"""act's full work-graph machinery, loaded by work_graph.py when present.

Adds to the core:

- backlog.md: open rows waiting for a slot. graph.md holds at most 25 open
  rows (operator direction 2026-09-21); the archive step refills it by rank.
- Mechanism-keyed findings (operator decision 2026-09-22): producers append
  rows to findings-inbox/<producer>.md with ids from their own block; the
  archive step ingests them into backlog.md, writes findings/<id>.md, creates
  one mechanism head M-n per key with two or more open members, and closes the
  members when their head closes.

Every function takes the core module as `core`, so this file never imports it.
"""

from __future__ import annotations

import re

BACKLOG = "backlog.md"
FILES = (BACKLOG,)
OPEN_CAP = 25  # operator direction 2026-09-21
SEVERITY_WEIGHT = {"Critical": 3, "Major": 2, "Minor": 1}  # operator decision 2026-09-22
TIER_COST = {"A": 3, "B": 2, "C": 1}  # operator decision 2026-09-22
KINDS = ("product", "harness", "corpus", "docs", "process")
UNIQUE = "unique"
INBOX = "findings-inbox"
MECHANISMS = "MECHANISMS.md"
INBOX_HEADER = ("ID", "Mechanism", "Kind", "Severity", "Width", "Item", "Refs")
MECHANISM_HEADER = ("Key", "Tier", "Definition")
TAG_RE = re.compile(
    r"^\*\*(?P<key>[a-z0-9][a-z0-9-]*)\*\* · (?P<kind>[a-z]+) · (?P<severity>Critical|Major|Minor) · "
    r"(?:tier (?P<tier>[ABC]) · )?w(?P<width>\d+) — "
)
KEY_RE = re.compile(r"^[a-z0-9][a-z0-9-]*$")
BLOCK_RE = re.compile(r"^([a-z][a-z0-9_-]*)=F-(\d+)\.\.(?:F-(\d+))?$")
PINNED = ("IN-PROGRESS",)
MEMBERS_CLOSED = "members closed"


def model_optional(row) -> bool:
    """A backlog row may carry Model `—` until the controller writes its contract."""
    return row.file == BACKLOG


def extra_rows(graph, core) -> list:
    return core.parse_rows(graph.docs.get(BACKLOG, []), BACKLOG, graph.malformed)


def contract_rows(graph, core) -> list:
    """Backlog rows that carry a Model must carry a contract (P1); a row with
    Model `—` is a finding that waits for its contract."""
    return [r for r in graph.extra if not r.closed and r.model in core.MODELS]


def marker_files(graph) -> list:
    folder = graph.root / INBOX
    return [(f"{INBOX}/{p.name}", p) for p in sorted(folder.glob("*.md"))] if folder.is_dir() else []


def tag(row):
    return TAG_RE.match(row.node)


def blocks(graph) -> dict[str, tuple[int, int | None]] | None:
    value = graph.settings.get("Findings")
    if not value:
        return None
    out: dict[str, tuple[int, int | None]] = {}
    for part in block_parts(value):
        match = BLOCK_RE.match(part)
        if match:
            out[match.group(1)] = (int(match.group(2)), int(match.group(3)) if match.group(3) else None)
    return out


def block_parts(value: str) -> list[str]:
    """The comma-separated parts after the first `blocks`; [""] when there is none."""
    body = value.split("blocks", 1)[1] if "blocks" in value else ""
    return [part.strip() for part in body.split(",")]


def block_defects(graph) -> list[str]:
    value = graph.settings.get("Findings")
    if not value:
        return []
    return [f"Findings: `{part}` is not a block; write <producer>=F-<low>..F-<high> or <producer>=F-<low>.."
            for part in block_parts(value) if not BLOCK_RE.match(part)]


def mechanisms(graph, core) -> dict[str, str]:
    """key -> tier from findings-inbox/MECHANISMS.md."""
    lines = core.read_lines(graph.root / INBOX / MECHANISMS) or []
    found = {}
    for _, cells in _tables(lines, MECHANISM_HEADER, core):
        if len(cells) == 3:
            found[cells[0]] = cells[1]
    return found


def mechanism_defects(graph, core) -> list[str]:
    return [f"{MECHANISMS}: key {key} must match [a-z0-9][a-z0-9-]*"
            for key in mechanisms(graph, core) if not KEY_RE.match(key)]


def _tables(lines, header, core):
    """Data rows of every table with `header`, anywhere in the file."""
    out, in_table = [], False
    for i, line in enumerate(lines):
        if not line.startswith("|"):
            in_table = False
            continue
        cells = core.split_cells(line)
        if tuple(cells) == header:
            in_table = True
            continue
        if in_table and not set(line.replace("|", "").strip()) <= set("-: "):
            out.append((i, cells))
    return out


def producer_of(name: str, declared) -> str | None:
    stem = name[:-3]
    matches = [p for p in declared if stem == p or stem.startswith(p + "-")]
    return max(matches, key=len) if matches else None


def inbox_rows(graph, core):
    """(file name, cells) for every inbox row, in file then line order."""
    folder = graph.root / INBOX
    if not folder.is_dir():
        return []
    rows = []
    for path in sorted(folder.glob("*.md")):
        if path.name in (MECHANISMS, "README.md"):
            continue
        for _, cells in _tables(core.read_lines(path) or [], INBOX_HEADER, core):
            rows.append((path.name, cells))
    return rows


def inbox_defects(graph, core) -> list[str]:
    declared = blocks(graph)
    if declared is None:
        return []
    refused = block_defects(graph)
    if refused:
        return refused
    known = mechanisms(graph, core)
    existing = {r.id for r in graph.all_rows()}
    defects = mechanism_defects(graph, core)
    counts: dict[str, int] = {}
    for _, cells in inbox_rows(graph, core):
        counts[cells[0]] = counts.get(cells[0], 0) + 1
    defects += [f"{fid} appears more than once in {INBOX}; give each finding its own id"
                for fid, n in counts.items() if n > 1]
    for name, cells in inbox_rows(graph, core):
        label = f"{INBOX}/{name}"
        producer = producer_of(name, declared)
        if producer is None:
            defects.append(f"{label}: {name[:-3]} is not a declared producer ({', '.join(declared)})")
            continue
        if len(cells) != len(INBOX_HEADER):
            defects.append(f"{label}: row has {len(cells)} cells; expected {len(INBOX_HEADER)}")
            continue
        fid, key, kind, severity, width = cells[:5]
        if key != UNIQUE and key not in known:
            defects.append(f"{label}: {fid}: mechanism {key} is not in {MECHANISMS}")
        if kind not in KINDS:
            defects.append(f"{label}: {fid}: kind {kind} is not one of {', '.join(KINDS)}")
        if severity not in SEVERITY_WEIGHT:
            defects.append(f"{label}: {fid}: severity {severity} is not Critical, Major or Minor")
        if not width.isdigit():
            defects.append(f"{label}: {fid}: width {width} is not a number")
        match = re.match(r"^F-(\d+)$", fid)
        if fid in existing:
            continue
        low, high = declared[producer]
        if not match or int(match.group(1)) < low or (high is not None and int(match.group(1)) > high):
            span = f"F-{low}..F-{high}" if high is not None else f"F-{low}.."
            defects.append(f"{label}: {fid} is outside the {producer} block {span}")
    return defects


def extra_checks(graph, core) -> list[str]:
    defects = []
    open_rows = sum(1 for r in graph.rows if not r.closed)
    if open_rows > OPEN_CAP:
        defects.append(f"graph.md: {open_rows} open rows; cap is {OPEN_CAP} (run archive)")
    for r in graph.extra:
        if r.closed:
            defects.append(f"backlog: {r.id} is {r.state}; closed rows go to history.md")
    return defects + inbox_defects(graph, core)


def open_heads(graph) -> dict[str, object]:
    """key -> open head row."""
    return {t.group("key"): r for r in graph.rows + graph.extra
            if not r.closed and (t := tag(r)) and t.group("kind") == "mechanism"}


def skip_ids(graph, core) -> set[str]:
    """Open members of a key whose head is open: the head carries them."""
    heads = open_heads(graph)
    return {r.id for r in graph.rows + graph.extra
            if not r.closed and (t := tag(r)) and t.group("kind") != "mechanism" and t.group("key") in heads}


def members(graph, key) -> list:
    return [r for r in graph.rows + graph.extra
            if not r.closed and (t := tag(r)) and t.group("kind") != "mechanism" and t.group("key") == key]


def head_score(graph, head) -> float:
    t = tag(head)
    weight = sum(SEVERITY_WEIGHT[tag(m).group("severity")] for m in members(graph, t.group("key")))
    return weight / TIER_COST.get(t.group("tier") or "B", TIER_COST["B"])


def next_ids(graph) -> list[str]:
    value = graph.settings.get("Next", "—")
    return [] if value in ("—", "") else [i.strip(" .") for i in re.split(r"[,\s]+", value) if i.strip(" .")]


def rank(graph, core) -> list[str]:
    """Open, unpinned rows of graph.md and backlog.md in work order: the Next
    ids, then mechanism heads by score, then the rest in file order."""
    skip = skip_ids(graph, core)
    rows = [r for r in graph.rows + graph.extra if not r.closed and r.state not in PINNED and r.id not in skip]
    order = {r.id: n for n, r in enumerate(rows)}
    nxt = [i for i in next_ids(graph) if i in order]
    heads = sorted((r for r in rows if (t := tag(r)) and t.group("kind") == "mechanism" and r.id not in nxt),
                   key=lambda r: (-head_score(graph, r), order[r.id]))
    head_ids = [r.id for r in heads]
    rest = [r.id for r in rows if r.id not in nxt and r.id not in head_ids]
    return nxt + head_ids + rest


def backlog_skeleton(graph, core) -> list[str]:
    title = next((line[2:].strip() for line in graph.docs.get(core.GRAPH, []) if line.startswith("# ")), "Work Graph")
    sep = "|" + "|".join("-" * (len(c) + 2) for c in core.NODE_HEADER) + "|"
    return [f"# {title} — Backlog", "", "Open nodes waiting for a slot in graph.md. Never resume from this file.", "",
            "## Nodes", "", "| " + " | ".join(core.NODE_HEADER) + " |", sep]


def with_cells(line: str, core, **changes) -> str:
    cells = core.split_cells(line)
    for name, value in changes.items():
        cells[core.NODE_HEADER.index(name)] = value
    return "| " + " | ".join(cells) + " |"


def ingest(graph, docs, core) -> list[str]:
    if blocks(graph) is None:
        return []
    defects = inbox_defects(graph, core)
    if defects:
        raise ValueError("inbox refused:\n" + "\n".join(defects))
    existing = {r.id for r in graph.all_rows()}
    new_lines, moves = [], []
    for name, cells in inbox_rows(graph, core):
        fid, key, kind, severity, width, item, refs = cells
        if fid in existing:
            continue
        existing.add(fid)
        new_lines.append(f"| {fid} | **{key}** · {kind} · {severity} · w{width} — {item} | — | TODO | — | findings/{fid}.md |")
        evidence = f"findings/{fid}.md"
        if not (graph.root / evidence).exists():
            docs[evidence] = [f"# {fid}", "", f"**Mechanism:** {key} · {kind} · {severity} · w{width}",
                              f"**Item:** {item}", f"**Refs:** {refs}", f"**Source:** {INBOX}/{name}"]
        moves.append(f"{fid} ingested from {INBOX}/{name} → backlog.md")
    if new_lines:
        core.insert_table_lines(docs.setdefault(BACKLOG, backlog_skeleton(graph, core)), "Nodes", core.NODE_HEADER, new_lines)
    return moves


def make_heads(graph, docs, core) -> list[str]:
    known = mechanisms(graph, core)
    heads = open_heads(graph)
    numbers = [int(r.id[2:]) for r in graph.all_rows() if re.match(r"^M-\d+$", r.id)]
    next_number = max(numbers, default=0) + 1
    new_lines, moves = [], []
    keys = []
    for r in graph.rows + graph.extra:
        t = tag(r)
        if t and not r.closed and t.group("kind") != "mechanism" and t.group("key") not in keys:
            keys.append(t.group("key"))
    for key in keys:
        tier = known.get(key)
        group = members(graph, key)
        if key == UNIQUE or tier not in TIER_COST or key in heads or len(group) < 2:
            continue
        worst = max((tag(m).group("severity") for m in group), key=lambda s: SEVERITY_WEIGHT[s])
        hid = f"M-{next_number}"
        next_number += 1
        new_lines.append(f"| {hid} | **{key}** · mechanism · {worst} · tier {tier} · w{len(group)} — {len(group)} open members | — | TODO | — | — |")
        moves.append(f"{hid} head for {key} ({len(group)} members) → backlog.md")
    if new_lines:
        core.insert_table_lines(docs.setdefault(BACKLOG, backlog_skeleton(graph, core)), "Nodes", core.NODE_HEADER, new_lines)
    return moves


def close_members(graph, docs, core) -> list[str]:
    moves = []
    for head in graph.rows + graph.extra:
        t = tag(head)
        if not t or t.group("kind") != "mechanism" or head.state != "DONE" or MEMBERS_CLOSED in head.refs:
            continue
        for m in members(graph, t.group("key")):
            docs[m.file][m.index] = with_cells(docs[m.file][m.index], core, State="DONE", Refs=f"closed by {head.id}")
            moves.append(f"{m.id} DONE (closed by {head.id})")
        refs = MEMBERS_CLOSED if head.refs in ("—", "") else f"{head.refs}; {MEMBERS_CLOSED}"
        docs[head.file][head.index] = with_cells(docs[head.file][head.index], core, Refs=refs)
    return moves


def has_contract(graph, row, core) -> bool:
    fields = core.contract(graph, row.id)
    return row.model in core.MODELS and fields is not None and all(fields.get(f) for f in core.CONTRACT_FIELDS)


def rebalance(graph, docs, core) -> list[str]:
    """Closed backlog rows go to history; graph.md's open rows become the pinned
    rows plus the top of the rank, ready rows first, contracted rows only."""
    moves = []
    closed_backlog = [r for r in graph.extra if r.closed]
    if closed_backlog:
        history = docs.setdefault(core.HISTORY, core.history_skeleton(graph))
        core.insert_table_lines(history, "Nodes", core.NODE_HEADER, [docs[BACKLOG][r.index] for r in closed_backlog])
        moves += [f"{r.id} {r.state} backlog.md → history.md" for r in closed_backlog]
    done = {r.id for r in graph.all_rows() if r.state == "DONE"}
    by_id = {r.id: r for r in graph.rows + graph.extra if not r.closed}
    pinned = [r for r in graph.rows if r.state in PINNED]
    ranked = [by_id[i] for i in rank(graph, core)]
    eligible = [r for r in ranked if r.file == core.GRAPH or has_contract(graph, r, core)]
    eligible.sort(key=lambda r: 0 if set(r.depends) <= done and r.state in ("TODO", "PLANNED") else 1)
    keep = {r.id for r in pinned} | {r.id for r in eligible[: max(0, OPEN_CAP - len(pinned))]}
    out_rows = [r for r in graph.rows if not r.closed and r.id not in keep]
    in_rows = [r for r in eligible if r.file == BACKLOG and r.id in keep]
    if out_rows:
        backlog = docs.setdefault(BACKLOG, backlog_skeleton(graph, core))
        core.insert_table_lines(backlog, "Nodes", core.NODE_HEADER, [docs[core.GRAPH][r.index] for r in out_rows])
        moves += [f"{r.id} graph.md → backlog.md" for r in out_rows]
    if in_rows:
        core.insert_table_lines(docs[core.GRAPH], "Nodes", core.NODE_HEADER, [docs[BACKLOG][r.index] for r in in_rows])
        moves += [f"{r.id} backlog.md → graph.md" for r in in_rows]
    # Delete moved lines from their source files by their original text, so the
    # insertions above (which shift indices) cannot misdirect a deletion.
    for name, rows in ((core.GRAPH, out_rows), (BACKLOG, in_rows + closed_backlog)):
        targets = [r.line for r in rows]
        if targets:
            kept, pending = [], list(targets)
            for line in docs[name]:
                normal = "| " + " | ".join(core.split_cells(line)) + " |" if line.startswith("|") else None
                if normal in pending:
                    pending.remove(normal)
                    continue
                kept.append(line)
            docs[name] = kept
    return moves


def pre_archive(graph, docs, core) -> list[str]:
    """Before the core trims closed rows: close members, ingest, create heads.
    Members close first, so a head that the trim moves to history still closes
    them, and a finding that arrives in this run is never closed by a head it
    was not part of. Each step reloads so it sees the previous step's rows."""
    moves = []
    for step in (close_members, ingest, make_heads):
        moves += step(core.load(graph.path, docs), docs, core)
    return moves


def post_archive(graph, docs, core) -> list[str]:
    """After the core trim: move closed backlog rows to history and refill."""
    return rebalance(graph, docs, core)


def extra_status(graph, core) -> list[str]:
    waiting = [r for r in graph.extra if not r.closed]
    awaiting = [r for r in waiting if not has_contract(graph, r, core)]
    lines = [f"backlog: {len(waiting)} open ({len(awaiting)} awaiting a contract)"]
    heads = open_heads(graph)
    if heads:
        lines.append("heads: " + ", ".join(
            f"{r.id} {k} w{len(members(graph, k))} score {head_score(graph, r):.1f}" for k, r in heads.items()))
    if next_ids(graph):
        lines.append("next: " + ", ".join(next_ids(graph)))
    return lines
