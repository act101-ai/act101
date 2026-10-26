#!/usr/bin/env python3
"""Check, schedule, report and archive a work graph.

Bundled with the work-graph companion of the plan-work and execute-work
skills. Standard library only.

    work_graph.py check   <graph.md>   refuse a malformed graph; exit 1 with one line per defect
    work_graph.py ready   <graph.md>   the nodes to run now
    work_graph.py status  <graph.md>   counts per state, the ready set, the schedule, stuck nodes
    work_graph.py archive <graph.md> [--dry-run]
                                       move closed rows and old Log entries to history.md

    --rows <file|->  read the nodes from a custom ledger's JSON export instead of
                     the node table (check, ready, status; archive then moves only
                     old Log entries)

A graph directory holds graph.md (header, node table, Log), nodes/<id>.md (one
contract per node) and history.md (closed rows and old Log entries). When the
module work_graph_full.py is beside this file, it adds the backlog and the
findings machinery; this file is the same in every repo that ships the skill.
"""

from __future__ import annotations

import argparse
import datetime as dt
import importlib.util
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

ID_RE = re.compile(r"^[A-Z]+-?\d+$")
LEDGER_ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")
STATE_RE = re.compile(r"^(TODO|PLANNED|IN-PROGRESS|DONE|BLOCKED\(.+\)|DROPPED\(.+\))$")
MODELS = ("haiku", "sonnet", "opus")
NONE = "—"
NODE_HEADER = ("ID", "Node", "Depends", "State", "Model", "Refs")
LOG_HEADER = ("Date", "Event")
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
SETTING_RE = re.compile(r"^\*\*([A-Za-z ]+):\*\*\s*(.*)$")
CONFLICT_RE = re.compile(r"^(<<<<<<< |=======$|>>>>>>> )")
RUN_TOKEN_RE = re.compile(r"([a-z][a-z-]*)\s*=\s*([^\s·;,]+)")
CONTRACT_FIELDS = ("Spec", "Files", "Consumes", "Produces", "Acceptance")
TICKED_RE = re.compile(r"`([^`]+)`")
PRODUCER_RE = re.compile(r"\s*\(([A-Za-z0-9][A-Za-z0-9._-]*)\)")
QUALIFIED_RE = re.compile(r"[A-Za-z_]\w*(?:(?:::|\.)[A-Za-z_]\w*)*")

ROW_CAP = 600  # operator decision 2026-09-22
LOG_ENTRY_CAP = 300  # operator decision 2026-09-22
CLOSED_CAP = 25  # operator direction 2026-09-21
LOG_WINDOW_DAYS = 14  # operator direction 2026-09-21
DEFAULT_PARALLEL = 3  # operator decision 2026-10-21

GRAPH = "graph.md"
HISTORY = "history.md"


@dataclass
class Row:
    id: str
    node: str
    depends: list[str]
    state: str
    model: str
    refs: str
    line: str  # normalized: "| " + " | ".join(cells) + " |"
    file: str
    index: int = -1  # line index in its file; -1 for a custom-ledger row

    @property
    def closed(self) -> bool:
        return self.state == "DONE" or self.state.startswith("DROPPED(")


@dataclass
class Graph:
    path: Path
    docs: dict[str, list[str]]  # file name -> raw lines, as on disk
    newlines: dict[str, str]
    settings: dict[str, str]
    rows: list[Row]
    history: list[Row]
    log: list[tuple[str, str]]
    extra: list[Row] = field(default_factory=list)
    malformed: list[str] = field(default_factory=list)
    ledger: bool = False  # rows came from a custom ledger's export (spec §4.7)
    missing: bool = False

    @property
    def root(self) -> Path:
        return self.path.parent

    def all_rows(self) -> list[Row]:
        return self.rows + self.extra + self.history

    def run(self) -> dict[str, str]:
        return dict(RUN_TOKEN_RE.findall(self.settings.get("Run", "")))

    def parallel(self) -> int:
        value = self.run().get("parallel", str(DEFAULT_PARALLEL))
        if value == "off":
            return 1
        return max(1, int(value)) if value.isdigit() else 1


def split_cells(line: str) -> list[str]:
    """The cells of a table row. A `|` inside a code span (any backtick run) or
    escaped as `\\|` is text."""
    body = line.strip()
    if body.startswith("|"):
        body = body[1:]
    if body.endswith("|") and not body.endswith("\\|"):
        body = body[:-1]
    cells, current, fence = [], [], 0
    i = 0
    while i < len(body):
        ch = body[i]
        if ch == "\\" and i + 1 < len(body) and body[i + 1] == "|":
            current.append("\\|")
            i += 2
            continue
        if ch == "`":
            run = len(body[i:]) - len(body[i:].lstrip("`"))
            if fence == 0:
                fence = run
            elif run == fence:
                fence = 0
            current.append("`" * run)
            i += run
            continue
        if ch == "|" and fence == 0:
            cells.append("".join(current).strip())
            current = []
        else:
            current.append(ch)
        i += 1
    cells.append("".join(current).strip())
    return cells


def normal(cells: list[str]) -> str:
    return "| " + " | ".join(cells) + " |"


def read_doc(path: Path) -> tuple[list[str], str] | None:
    """The file's raw lines and its newline style, or None when it is absent."""
    if not path.is_file():
        return None
    data = path.read_bytes().decode("utf-8")
    return data.splitlines(), ("\r\n" if "\r\n" in data else "\n")


def read_lines(path: Path) -> list[str] | None:
    doc = read_doc(path)
    return None if doc is None else [line.rstrip() for line in doc[0]]


def is_separator(line: str) -> bool:
    return set(line.replace("|", "").strip()) <= set("-: ")


def find_table(lines: list[str], section: str, header: tuple[str, ...]) -> int | None:
    """The line index of the `header` row under `## section`, or None."""
    in_section = False
    for i, raw in enumerate(lines):
        line = raw.rstrip()
        if line.startswith("## "):
            in_section = line[3:].strip() == section
            continue
        if in_section and line.startswith("|") and tuple(split_cells(line)) == header:
            return i
    return None


def section_tables(lines: list[str], section: str, header: tuple[str, ...]) -> list[tuple[int, list[str]]]:
    """(line index, cells) of every data row of the table with `header` under `## section`."""
    out: list[tuple[int, list[str]]] = []
    in_section = in_table = False
    for i, raw in enumerate(lines):
        line = raw.rstrip()
        if line.startswith("## "):
            in_section = line[3:].strip() == section
            in_table = False
            continue
        if not in_section:
            continue
        if not line.startswith("|"):
            in_table = False
            continue
        cells = split_cells(line)
        if tuple(cells) == header:
            in_table = True
            continue
        if in_table and not is_separator(line):
            out.append((i, cells))
    return out


def parse_rows(lines: list[str], file: str, malformed: list[str]) -> list[Row]:
    rows = []
    for index, cells in section_tables(lines, "Nodes", NODE_HEADER):
        if len(cells) != len(NODE_HEADER) or not ID_RE.match(cells[0]):
            malformed.append(f"{file}: malformed node row: {normal(cells)}")
            continue
        depends = [] if cells[2] in (NONE, "") else [d.strip() for d in cells[2].split(",")]
        rows.append(Row(cells[0], cells[1], depends, cells[3], cells[4], cells[5], normal(cells), file, index))
    return rows


def ledger_rows(data: object, malformed: list[str]) -> list[Row]:
    """Rows from a custom ledger's normalized JSON export (spec §4.7)."""
    if not isinstance(data, list):
        malformed.append("rows: the export must be a JSON list of node objects")
        return []
    rows = []
    for n, item in enumerate(data, 1):
        if not isinstance(item, dict):
            malformed.append(f"row {n}: not an object")
            continue
        missing = [k for k in ("id", "depends", "state", "model") if k not in item]
        if missing:
            malformed.append(f"row {n}: missing {', '.join(missing)}")
            continue
        node_id = str(item["id"])
        if not LEDGER_ID_RE.match(node_id) or not isinstance(item["depends"], list):
            malformed.append(f"row {n}: id {node_id!r} or depends is malformed")
            continue
        depends = [str(d) for d in item["depends"]]
        node, refs = str(item.get("node", "")), str(item.get("refs", ""))
        line = normal([node_id, node, ", ".join(depends) or NONE, str(item["state"]), str(item["model"]), refs])
        rows.append(Row(node_id, node, depends, str(item["state"]), str(item["model"]), refs, line, "ledger"))
    return rows


def log_entries(lines: list[str]) -> list[tuple[int, str, str]]:
    return [(i, c[0], c[1]) for i, c in section_tables(lines, "Log", LOG_HEADER) if len(c) == 2]


def load(path: Path | str, docs: dict[str, list[str]] | None = None, rows: object = None) -> Graph:
    """Parse the graph at `path`. `docs` (file name -> raw lines) overrides what is
    on disk. `rows` is a custom ledger's JSON export; it replaces the node table."""
    path = Path(path)
    docs = dict(docs or {})
    newlines: dict[str, str] = {}
    ext = EXT if rows is None else None
    for name in (GRAPH, HISTORY) + (tuple(ext.FILES) if ext else ()):
        doc = read_doc(path if name == GRAPH else path.parent / name)
        if doc is not None:
            newlines[name] = doc[1]
            docs.setdefault(name, doc[0])
    graph_lines = docs.get(GRAPH, [])
    settings = {}
    for raw in graph_lines:
        line = raw.rstrip()
        if line.startswith("## "):
            break
        match = SETTING_RE.match(line)
        if match:
            settings[match.group(1)] = match.group(2).strip()
    malformed: list[str] = []
    graph = Graph(
        path=path,
        docs=docs,
        newlines=newlines,
        settings=settings,
        rows=parse_rows(graph_lines, GRAPH, malformed) if rows is None else ledger_rows(rows, malformed),
        history=parse_rows(docs.get(HISTORY, []), HISTORY, malformed) if rows is None else [],
        log=[(d, e) for _, d, e in log_entries(graph_lines)],
        malformed=malformed,
        ledger=rows is not None,
        missing=GRAPH not in docs,
    )
    if ext:
        graph.extra = ext.extra_rows(graph, sys.modules[__name__])
    return graph


def ext_for(graph: Graph):
    """The full machinery for this graph: none for a custom ledger."""
    return None if graph.ledger else EXT


def contract(graph: Graph, node_id: str) -> dict[str, str] | None:
    lines = read_lines(graph.root / "nodes" / f"{node_id}.md")
    if lines is None:
        return None
    fields = {}
    for line in lines:
        match = SETTING_RE.match(line)
        if match and match.group(1) in CONTRACT_FIELDS:
            fields[match.group(1)] = match.group(2).strip()
    return fields


def ticked(value: str) -> list[str]:
    return [] if value in (NONE, "") else TICKED_RE.findall(value)


def item_name(text: str) -> str:
    """The name a Produces or Consumes item declares: the identifier, with its path
    (`config::load`, `Config.load`), before `(`; a leading keyword (`fn load(`) is
    dropped. Without `(`, the leading qualified identifier (`MAX: usize` → MAX)."""
    text = text.strip()
    if "(" in text:
        head = text.split("(", 1)[0].strip()
        head = re.sub(r"<[^<>]*>$", "", head).strip()
        return head.split()[-1] if head.split() else head
    match = QUALIFIED_RE.match(text)
    return match.group(0) if match else text


def names_match(consumed: str, produced: str) -> bool:
    """A consumed name matches a produced name exactly, or names its last segment."""
    return consumed == produced or produced.endswith("::" + consumed) or produced.endswith("." + consumed)


def consumed_items(value: str) -> tuple[list[tuple[str, str]], list[str]]:
    """(name, producer id) for each `name` (ID) item, and the items without an id."""
    found, orphans = [], []
    for match in TICKED_RE.finditer(value):
        producer = PRODUCER_RE.match(value, match.end())
        if producer:
            found.append((item_name(match.group(1)), producer.group(1)))
        else:
            orphans.append(match.group(1))
    return found, orphans


def ancestors(graph: Graph) -> dict[str, set[str]]:
    deps = {r.id: set(r.depends) for r in graph.all_rows()}
    memo: dict[str, set[str]] = {}

    def walk(node: str, seen: frozenset[str]) -> set[str]:
        if node in memo:
            return memo[node]
        out: set[str] = set()
        for dep in deps.get(node, ()):
            if dep in seen:
                continue
            out.add(dep)
            out |= walk(dep, seen | {dep})
        memo[node] = out
        return out

    return {node: walk(node, frozenset({node})) for node in deps}


def find_cycles(graph: Graph) -> list[list[str]]:
    deps = {r.id: list(r.depends) for r in graph.all_rows()}
    color: dict[str, int] = {}
    cycles: list[list[str]] = []

    def visit(node: str, stack: list[str]) -> None:
        color[node] = 1
        stack.append(node)
        for dep in deps.get(node, []):
            if dep not in deps:
                continue
            if color.get(dep) == 1:
                cycles.append(stack[stack.index(dep):] + [dep])
            elif dep not in color:
                visit(dep, stack)
        stack.pop()
        color[node] = 2

    for node in deps:
        if node not in color:
            visit(node, [])
    return cycles


def conflict_markers(graph: Graph) -> list[str]:
    """The first conflict marker in each graph file, node file and (full) inbox file."""
    sources: list[tuple[str, list[str]]] = list(graph.docs.items())
    for path in sorted((graph.root / "nodes").glob("*.md")):
        sources.append((f"nodes/{path.name}", read_lines(path) or []))
    if ext_for(graph):
        for label, path in EXT.marker_files(graph):
            sources.append((label, read_lines(path) or []))
    out = []
    for name, lines in sources:
        for i, line in enumerate(lines, 1):
            if CONFLICT_RE.match(line.rstrip()):
                out.append(f"{name}:{i}: conflict marker; resolve the merge first")
                break
    return out


def contract_rows(graph: Graph) -> list[Row]:
    """The open rows that must carry a contract."""
    rows = [r for r in graph.rows if not r.closed]
    if ext_for(graph):
        rows += EXT.contract_rows(graph, sys.modules[__name__])
    return rows


def check(graph: Graph) -> list[str]:
    """Every defect in the graph, one line each. An empty list means it passes."""
    if graph.missing:
        return [f"{graph.path}: not found"]
    markers = conflict_markers(graph)
    if markers:
        return markers
    defects = list(graph.malformed)
    if not graph.ledger and find_table(graph.docs[GRAPH], "Nodes", NODE_HEADER) is None:
        defects.append("graph.md: no node table; `## Nodes` must hold a table with the header " + normal(list(NODE_HEADER)))
    for name in (HISTORY,) + (tuple(EXT.FILES) if ext_for(graph) else ()):
        if name in graph.docs and find_table(graph.docs[name], "Nodes", NODE_HEADER) is None:
            defects.append(f"{name}: no node table under `## Nodes`")
    value = graph.run().get("parallel")
    if value is not None and value != "off" and not (value.isdigit() and int(value) >= 1):
        defects.append(f"Run: parallel={value} is not a whole number or off")

    rows = graph.all_rows()
    ids = {r.id for r in rows}
    seen: set[str] = set()
    for r in rows:
        if r.id in seen:
            defects.append(f"duplicate id {r.id} ({r.file})")
        seen.add(r.id)
        if not STATE_RE.match(r.state):
            defects.append(f"{r.id}: state {r.state} is not TODO, PLANNED, IN-PROGRESS, DONE, BLOCKED(reason) or DROPPED(evidence)")
        if r.model not in MODELS and not (r.model == NONE and (r.closed or (ext_for(graph) and EXT.model_optional(r)))):
            defects.append(f"{r.id}: model {r.model} is not haiku, sonnet or opus")
        if len(r.line) > ROW_CAP and not graph.ledger:
            defects.append(f"{r.id}: row exceeds {ROW_CAP} characters ({len(r.line)}); move detail to nodes/{r.id}.md")
        for dep in r.depends:
            if dep not in ids:
                defects.append(f"{r.id} depends on unknown node {dep}")
    for r in graph.history:
        if not r.closed:
            defects.append(f"history: {r.id} is {r.state}; history holds only DONE or DROPPED")
    for cycle in find_cycles(graph):
        defects.append("cycle: " + " → ".join(cycle))

    anc = ancestors(graph)
    contracts: dict[str, dict[str, str]] = {}
    for r in contract_rows(graph):
        fields = contract(graph, r.id)
        if fields is None:
            defects.append(f"{r.id}: no contract file nodes/{r.id}.md")
            continue
        contracts[r.id] = fields
        for name in CONTRACT_FIELDS:
            if not fields.get(name):
                defects.append(f"{r.id}: contract missing {name}")
        acceptance = fields.get("Acceptance", "")
        if acceptance and not (TICKED_RE.search(acceptance) and "→" in acceptance):
            defects.append(f"{r.id}: Acceptance needs a `command` and → expected output")
        consumes = fields.get("Consumes", NONE)
        items, orphans = consumed_items(consumes)
        if consumes not in (NONE, "") and not items and not orphans:
            defects.append(f"{r.id}: Consumes lists `name` (ID) items, or —")
        for text in orphans:
            defects.append(f"{r.id}: Consumes item `{text}` names no producer (ID)")
        for name, producer in items:
            if producer not in anc.get(r.id, set()):
                defects.append(f"{r.id} consumes from {producer} but does not depend on it")
                continue
            producer_fields = contracts.get(producer) or contract(graph, producer)
            if producer_fields is None:
                defects.append(f"{r.id} consumes {name} from {producer}, which has no contract file")
            elif not any(names_match(name, item_name(p)) for p in ticked(producer_fields.get("Produces", NONE))):
                defects.append(f"{r.id} consumes {name} from {producer}, which does not produce it")

    open_ids = list(contracts)
    for i, a in enumerate(open_ids):
        for b in open_ids[i + 1:]:
            if a in anc.get(b, set()) or b in anc.get(a, set()):
                continue
            shared = overlapping(set(ticked(contracts[a].get("Files", NONE))), set(ticked(contracts[b].get("Files", NONE))))
            for path in shared:
                defects.append(f"{a} and {b} both change {path} but neither depends on the other")

    closed = sum(1 for r in graph.rows if r.closed)
    if closed > CLOSED_CAP and not graph.ledger:
        defects.append(f"graph.md: {closed} closed rows; cap is {CLOSED_CAP} (run archive)")
    for date, event in graph.log:
        if len(normal([date, event])) > LOG_ENTRY_CAP:
            defects.append(f"Log entry {date} exceeds {LOG_ENTRY_CAP} characters")
    for date in old_log_dates(graph):
        defects.append(f"Log entry {date} is older than {LOG_WINDOW_DAYS} days before the newest entry (run archive)")
    if ext_for(graph):
        defects += EXT.extra_checks(graph, sys.modules[__name__])
    return defects


def old_log_dates(graph: Graph) -> list[str]:
    dates = [d for d, _ in graph.log if DATE_RE.match(d)]
    if not dates:
        return []
    newest = max(dt.date.fromisoformat(d) for d in dates)
    cutoff = newest - dt.timedelta(days=LOG_WINDOW_DAYS)
    return [d for d in dates if dt.date.fromisoformat(d) < cutoff]


def overlapping(a: set[str], b: set[str]) -> list[str]:
    """Paths two Files lists both change. Equal entries overlap; an entry
    ending in `/` names a directory and overlaps every entry under it. Each
    overlap is reported by its more specific path."""
    out = set()
    for x in a:
        for y in b:
            if x == y or (x.endswith("/") and y.startswith(x)):
                out.add(y)
            elif y.endswith("/") and x.startswith(y):
                out.add(x)
    return sorted(out)


def files_of(graph: Graph, node_id: str) -> set[str]:
    fields = contract(graph, node_id)
    return set(ticked(fields.get("Files", NONE))) if fields else set()


def ready_set(graph: Graph) -> list[str]:
    """Every node in graph.md in state TODO or PLANNED whose dependencies are all DONE."""
    done = {r.id for r in graph.all_rows() if r.state == "DONE"}
    skip = EXT.skip_ids(graph, sys.modules[__name__]) if ext_for(graph) else set()
    return [r.id for r in graph.rows
            if r.state in ("TODO", "PLANNED") and r.id not in skip and set(r.depends) <= done]


def schedule(graph: Graph) -> list[tuple[str, str]]:
    """The nodes to run now: IN-PROGRESS nodes, then ready nodes in table order,
    up to the parallel setting, skipping a node whose Files overlap a node
    already in the schedule."""
    out = [(r.id, "IN-PROGRESS") for r in graph.rows if r.state == "IN-PROGRESS"]
    used: set[str] = set()
    for node_id, _ in out:
        used |= files_of(graph, node_id)
    for node_id in ready_set(graph):
        if len(out) >= graph.parallel():
            break
        files = files_of(graph, node_id)
        if overlapping(files, used):
            continue
        out.append((node_id, "ready"))
        used |= files
    return out


def stuck(graph: Graph) -> list[str]:
    """Open nodes that can never become ready without a decision: BLOCKED nodes,
    and nodes that depend on a DROPPED or BLOCKED node."""
    states = {r.id: r.state for r in graph.all_rows()}
    out = []
    for r in graph.rows + graph.extra:
        if r.state.startswith("BLOCKED("):
            out.append(f"{r.id} (BLOCKED)")
            continue
        if r.closed:
            continue
        for dep in r.depends:
            state = states.get(dep, "")
            if state.startswith(("DROPPED(", "BLOCKED(")):
                out.append(f"{r.id} (depends on {state.split('(')[0]} {dep})")
                break
    return out


def status(graph: Graph) -> str:
    def counts(rows: list[Row]) -> str:
        names = ("TODO", "PLANNED", "IN-PROGRESS", "BLOCKED", "DONE", "DROPPED")
        tally = {n: 0 for n in names}
        for r in rows:
            key = r.state.split("(")[0]
            tally[key] = tally.get(key, 0) + 1
        return " · ".join(f"{n} {tally[n]}" for n in names)

    ready = ready_set(graph)
    planned = [f"{i}" for i, _ in schedule(graph)]
    lines = [
        f"graph: {counts(graph.rows)}",
        f"ready: {', '.join(ready) if ready else NONE}",
        f"schedule: {', '.join(planned) if planned else NONE}",
        f"stuck: {', '.join(stuck(graph)) or NONE}",
        f"history: {len(graph.history)}",
    ]
    if ext_for(graph):
        lines += EXT.extra_status(graph, sys.modules[__name__])
    return "\n".join(lines)


def table_skeleton(section: str, header: tuple[str, ...]) -> list[str]:
    sep = "|" + "|".join("-" * (len(c) + 2) for c in header) + "|"
    return [f"## {section}", "", normal(list(header)), sep]


def insert_table_lines(lines: list[str], section: str, header: tuple[str, ...], new: list[str]) -> None:
    """Append `new` after the last row of the `header` table under `## section`;
    add the section and the table at the end of the file when they are absent."""
    if not new:
        return
    head = find_table(lines, section, header)
    if head is None:
        if lines and lines[-1].strip():
            lines.append("")
        lines.extend(table_skeleton(section, header))
        head = len(lines) - 2
    end = head + 1
    while end < len(lines) and lines[end].lstrip().startswith("|"):
        end += 1
    lines[end:end] = new


def history_skeleton(graph: Graph) -> list[str]:
    title = next((line[2:].strip() for line in graph.docs.get(GRAPH, []) if line.startswith("# ")), "Work Graph")
    return ([f"# {title} — History", "",
             "Closed node rows and Log entries moved from graph.md, verbatim. Append-only.", ""]
            + table_skeleton("Nodes", NODE_HEADER) + [""] + table_skeleton("Log", LOG_HEADER))


def write_docs(graph: Graph, docs: dict[str, list[str]]) -> None:
    for name, lines in docs.items():
        if graph.docs.get(name) != lines:
            target = graph.path if name == GRAPH else graph.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            newline = graph.newlines.get(name, graph.newlines.get(GRAPH, "\n"))
            target.write_bytes((newline.join(lines) + newline).encode("utf-8"))


def trim(graph: Graph, docs: dict[str, list[str]]) -> list[str]:
    """Move closed rows of graph.md beyond the cap (oldest first, unless a ledger
    holds the rows) and Log entries beyond the window to history.md, verbatim."""
    lines = docs[GRAPH]
    closed = [] if graph.ledger else [r for r in graph.rows if r.closed]
    excess = closed[: max(0, len(closed) - CLOSED_CAP)]
    old = set(old_log_dates(graph))
    old_log = [(i, d) for i, d, _ in log_entries(lines) if d in old]
    if not excess and not old_log:
        return []
    history = docs.setdefault(HISTORY, history_skeleton(graph))
    insert_table_lines(history, "Nodes", NODE_HEADER, [lines[r.index] for r in excess])
    insert_table_lines(history, "Log", LOG_HEADER, [lines[i] for i, _ in old_log])
    for i in sorted([r.index for r in excess] + [i for i, _ in old_log], reverse=True):
        del lines[i]
    return [f"{r.id} {r.state} → history.md" for r in excess] + [f"Log {d} → history.md" for _, d in old_log]


def archive(graph: Graph, dry_run: bool = False) -> list[str]:
    """Move closed rows beyond the cap and Log entries beyond the window from
    graph.md to history.md, verbatim; with the full machinery, close members,
    ingest findings, create heads, and refill from the backlog. Returns one line
    per move. A second run moves nothing."""
    docs = {name: list(lines) for name, lines in graph.docs.items()}
    moves: list[str] = []
    core = sys.modules[__name__]
    ext = ext_for(graph)
    if ext:
        moves += ext.pre_archive(graph, docs, core)
    current = load(graph.path, docs) if not graph.ledger else graph
    moves += trim(current, docs)
    if ext:
        moves += ext.post_archive(load(graph.path, docs), docs, core)
    if not dry_run and moves:
        write_docs(graph, docs)
    return moves


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("command", choices=["check", "ready", "status", "archive"])
    parser.add_argument("graph", type=Path)
    parser.add_argument("--rows", help="a custom ledger's JSON export (file, or - for stdin)")
    parser.add_argument("--dry-run", action="store_true", help="archive: report the moves, write nothing")
    args = parser.parse_args(argv)
    rows = None
    if args.rows is not None:
        text = sys.stdin.read() if args.rows == "-" else Path(args.rows).read_text(encoding="utf-8")
        try:
            rows = json.loads(text)
        except json.JSONDecodeError as err:
            print(f"rows: not valid JSON ({err})")
            return 1
    graph = load(args.graph, rows=rows)
    if args.command == "archive":
        refusals = ([f"{graph.path}: not found"] if graph.missing else []) or conflict_markers(graph) or graph.malformed
        if refusals:
            for line in refusals:
                print(line)
            return 1
        try:
            moves = archive(graph, dry_run=args.dry_run)
        except ValueError as err:
            print(err)
            return 1
        for move in moves:
            print(move)
        return 0
    defects = check(graph)
    if args.command == "check" or defects:
        for defect in defects:
            print(defect)
        if not defects:
            print(f"{args.graph}: ok")
        return 1 if defects else 0
    if args.command == "ready":
        for node_id, kind in schedule(graph):
            print(f"{node_id} {kind}")
    else:
        print(status(graph))
    return 0


def load_full():
    """work_graph_full.py from this file's directory, or None when the repo does not ship it."""
    path = Path(__file__).resolve().parent / "work_graph_full.py"
    if not path.is_file():
        return None
    spec = importlib.util.spec_from_file_location("work_graph_full", path)
    module = importlib.util.module_from_spec(spec)
    sys.modules["work_graph_full"] = module
    spec.loader.exec_module(module)
    return module


EXT = load_full()


if __name__ == "__main__":
    sys.exit(main())
