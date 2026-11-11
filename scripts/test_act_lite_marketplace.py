"""Smoke all three harness installs with act-lite on PATH or ACT_LITE_BIN set."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
PLUGIN = ROOT / "plugin-act-lite"


def run(*args: str, env: dict[str, str]) -> str:
    result = subprocess.run(args, env=env, text=True, capture_output=True, timeout=60)
    if result.returncode:
        raise AssertionError(f"{' '.join(args)} failed:\n{result.stdout}\n{result.stderr}")
    return result.stdout + result.stderr


def marketplace_install_smoke() -> None:
    for manifest in (".claude-plugin/marketplace.json", ".codex-plugin/marketplace.json"):
        plugins = json.loads((ROOT / manifest).read_text())["plugins"]
        act_lite = [p for p in plugins if p["name"] == "act-lite"]
        assert len(act_lite) == 1, f"{manifest}: expected one act-lite entry"
        assert act_lite[0]["version"] == "1.2.2"
        source = act_lite[0]["source"]
        assert source == "./plugin-act-lite" or source == {"source": "local", "path": "./plugin-act-lite"}

    assert (PLUGIN / ".claude-plugin/plugin.json").is_file()
    assert (PLUGIN / ".mcp.json").is_file()
    assert (PLUGIN / ".codex-plugin/plugin.json").is_file()
    assert (PLUGIN / ".codex-plugin/mcp.json").is_file()
    binary = os.environ.get("ACT_LITE_BIN") or shutil.which("act-lite")
    assert binary and Path(binary).is_file(), "install act-lite or set ACT_LITE_BIN"
    assert "act-lite 1.2.2" in run(str(binary), "--version", env=os.environ.copy())

    with tempfile.TemporaryDirectory(prefix="act-lite-marketplace-") as scratch:
        scratch = Path(scratch)
        env = os.environ.copy()
        env["HOME"] = str(scratch / "home")
        env["CLAUDE_CONFIG_DIR"] = str(scratch / "claude")
        env["CODEX_HOME"] = str(scratch / "codex")
        env["XDG_CONFIG_HOME"] = str(scratch / "config")
        for name in ("home", "claude", "codex", "config"):
            (scratch / name).mkdir()
        bin_dir = scratch / "bin"
        bin_dir.mkdir()
        (bin_dir / "act-lite").symlink_to(Path(binary).resolve())
        env["PATH"] = f"{bin_dir}{os.pathsep}{env['PATH']}"

        run("claude", "plugin", "marketplace", "add", str(ROOT), env=env)
        run("claude", "plugin", "install", "act-lite@act101-marketplace", env=env)
        installed = run("claude", "plugin", "list", "--json", env=env)
        assert "act-lite@act101-marketplace" in installed, installed

        run("codex", "plugin", "marketplace", "add", str(ROOT), env=env)
        run("codex", "plugin", "add", "act-lite@act101-marketplace", env=env)
        installed = run("codex", "plugin", "list", "--json", env=env)
        assert "act-lite" in installed, installed

        config = scratch / "config/opencode"
        config.mkdir()
        shutil.copytree(PLUGIN / "skills", config / "skills")
        (config / "opencode.json").write_text(json.dumps({
            "mcp": {"act-lite": {"type": "local", "command": ["act-lite", "mcp", "serve"], "enabled": True}}
        }))
        result = run("opencode", "mcp", "list", "--pure", env=env)
        assert "act-lite" in result, result
        assert "connected" in result and "failed" not in result, result
        assert (config / "skills/execute-work/SKILL.md").is_file()


if __name__ == "__main__":
    marketplace_install_smoke()
    print("Claude Code, Codex, and OpenCode installation smoke passed")
