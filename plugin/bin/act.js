#!/usr/bin/env node
// Launcher for the act Claude Code plugin.
//
// On first run: detects host target triple, downloads the matching
// act binary from the pinned GitHub Release into CLAUDE_PLUGIN_DATA,
// and execs it. Subsequent runs exec the cached binary directly.
//
// Modes:
//   node act.js --ensure           Download + verify only (used by SessionStart hook).
//   node act.js <args...>          Ensure, then exec the binary with args.

'use strict';

const fs = require('node:fs');
const path = require('node:path');
const https = require('node:https');
const os = require('node:os');
const { spawn, spawnSync } = require('node:child_process');
const { pipeline } = require('node:stream/promises');
const { createGunzip } = require('node:zlib');

const PLUGIN_ROOT = process.env.CLAUDE_PLUGIN_ROOT || path.resolve(__dirname, '..');
const PLUGIN_DATA = process.env.CLAUDE_PLUGIN_DATA || path.join(PLUGIN_ROOT, '.data');
const REPO = 'act101-ai/act101';

function log(msg) {
    process.stderr.write(`[act-plugin] ${msg}\n`);
}

function die(msg, code = 1) {
    process.stderr.write(`[act-plugin] error: ${msg}\n`);
    process.exit(code);
}

// Host plugin manifests, in preference order. The payload is shared across
// Claude Code, Codex, and Cursor, so whichever host installed it determines
// which manifest dir is present. All carry the same version (release-prepare
// bumps them in lockstep), so any match is an acceptable version floor.
const MANIFEST_DIRS = ['.cursor-plugin', '.codex-plugin', '.claude-plugin'];

function readPluginVersion(root = PLUGIN_ROOT) {
    const tried = [];
    for (const dir of MANIFEST_DIRS) {
        const manifest = path.join(root, dir, 'plugin.json');
        tried.push(manifest);
        if (!fs.existsSync(manifest)) continue;
        const { version } = JSON.parse(fs.readFileSync(manifest, 'utf8'));
        if (!version || typeof version !== 'string') {
            die(`plugin.json is missing a version field at ${manifest}`);
        }
        return version;
    }
    die(`no plugin.json with a version found in any of: ${tried.join(', ')}`);
}

function detectTarget() {
    const { platform, arch } = process;
    // Linux: prefer musl (statically linked, no glibc version requirement)
    // over gnu, which links against the builder's glibc and breaks on
    // older hosts. We only ship musl for x86_64; aarch64 uses gnu until
    // we add a musl aarch64 build.
    const map = {
        'linux:x64':   'x86_64-unknown-linux-musl',
        'linux:arm64': 'aarch64-unknown-linux-gnu',
        'darwin:x64':  'x86_64-apple-darwin',
        'darwin:arm64':'aarch64-apple-darwin',
        'win32:x64':   'x86_64-pc-windows-msvc',
        'win32:arm64': 'aarch64-pc-windows-msvc',
    };
    const key = `${platform}:${arch}`;
    const target = map[key];
    if (!target) {
        die(`unsupported platform ${key}. Supported: ${Object.keys(map).join(', ')}`);
    }
    return target;
}

function binaryName() {
    return process.platform === 'win32' ? 'act.exe' : 'act';
}

function archiveName(target) {
    return process.platform === 'win32'
        ? `act-${target}.zip`
        : `act-${target}.tar.gz`;
}

function binaryPath(version, target) {
    return path.join(PLUGIN_DATA, 'bin', `v${version}`, target, binaryName());
}

function downloadUrl(version, target) {
    return `https://github.com/${REPO}/releases/download/v${version}/${archiveName(target)}`;
}

function fetchWithRedirects(url, dest, maxRedirects = 5) {
    return new Promise((resolve, reject) => {
        const attempt = (currentUrl, remaining) => {
            const req = https.get(currentUrl, (res) => {
                const { statusCode, headers } = res;
                if (statusCode >= 300 && statusCode < 400 && headers.location) {
                    res.resume();
                    if (remaining <= 0) return reject(new Error(`too many redirects from ${url}`));
                    const next = new URL(headers.location, currentUrl).toString();
                    return attempt(next, remaining - 1);
                }
                if (statusCode !== 200) {
                    res.resume();
                    return reject(new Error(`GET ${currentUrl} → HTTP ${statusCode}`));
                }
                const file = fs.createWriteStream(dest);
                pipeline(res, file).then(resolve, reject);
            });
            req.on('error', reject);
        };
        attempt(url, maxRedirects);
    });
}

function extractArchive(archivePath, destDir) {
    fs.mkdirSync(destDir, { recursive: true });
    if (archivePath.endsWith('.tar.gz')) {
        const result = spawnSync('tar', ['-xzf', archivePath, '-C', destDir], { stdio: 'inherit' });
        if (result.status !== 0) die(`tar extraction failed for ${archivePath}`);
    } else if (archivePath.endsWith('.zip')) {
        // Expand-Archive ships with Windows PowerShell 5+.
        const cmd = `Expand-Archive -Path '${archivePath}' -DestinationPath '${destDir}' -Force`;
        const result = spawnSync('powershell', ['-NoProfile', '-Command', cmd], { stdio: 'inherit' });
        if (result.status !== 0) die(`Expand-Archive failed for ${archivePath}`);
    } else {
        die(`unknown archive format: ${archivePath}`);
    }
}

function parseVersion(s) {
    const m = /(\d+)\.(\d+)\.(\d+)/.exec(String(s));
    if (!m) return null;
    return [Number(m[1]), Number(m[2]), Number(m[3])];
}

function compareVersions(a, b) {
    for (let i = 0; i < 3; i++) {
        if (a[i] !== b[i]) return a[i] < b[i] ? -1 : 1;
    }
    return 0;
}

// The `act mcp` surface is a stable contract within a major version, so the
// plugin's pinned version is a *floor*, not an exact target: any same-major
// binary at or above the floor satisfies what the shipped skills call. A
// different major may have moved the contract; an older binary may lack
// tools we depend on. Reuse iff same major AND >= floor.
function isCompatible(candidate, floor) {
    const c = parseVersion(candidate);
    const f = parseVersion(floor);
    if (!c || !f) return false;
    return c[0] === f[0] && compareVersions(c, f) >= 0;
}

function probePathBinary(floor, quiet = false) {
    // Look for an `act` already on PATH — the shell installer places one
    // there, and it self-updates. Reuse it when it satisfies the contract
    // (same major, >= floor) so the plugin rides those updates instead of
    // pinning a stale copy.
    const say = quiet ? () => {} : log;
    const name = binaryName();
    const probe = spawnSync(process.platform === 'win32' ? 'where' : 'which', [name], {
        encoding: 'utf8',
    });
    if (probe.status !== 0 || !probe.stdout) return null;
    const candidate = probe.stdout.split(/\r?\n/).map((s) => s.trim()).find(Boolean);
    if (!candidate || !fs.existsSync(candidate)) return null;

    const v = spawnSync(candidate, ['--version'], { encoding: 'utf8' });
    if (v.status !== 0) return null;
    const match = /(\d+\.\d+\.\d+)/.exec(v.stdout || '');
    if (!match) return null;
    if (!isCompatible(match[1], floor)) {
        say(`ignoring ${candidate} (v${match[1]} not compatible with plugin floor v${floor})`);
        return null;
    }
    say(`using PATH binary ${candidate} (v${match[1]}, plugin floor v${floor})`);
    return candidate;
}

async function ensureBinary({ quiet = false } = {}) {
    const say = quiet ? () => {} : log;
    const floor = readPluginVersion();
    const target = detectTarget();

    // 1. Prefer a compatible binary already on PATH (the self-updating shell
    //    install) so the plugin rides its updates.
    const onPath = probePathBinary(floor, quiet);
    if (onPath) return onPath;

    // 2. Otherwise reuse our own previously-downloaded copy at the floor.
    const bin = binaryPath(floor, target);
    if (fs.existsSync(bin)) return bin;

    // 3. Last resort: download the floor release.
    const url = downloadUrl(floor, target);
    const destDir = path.dirname(bin);
    fs.mkdirSync(destDir, { recursive: true });

    const archivePath = path.join(destDir, archiveName(target));
    say(`downloading ${url}`);
    await fetchWithRedirects(url, archivePath);

    say(`extracting to ${destDir}`);
    extractArchive(archivePath, destDir);

    if (!fs.existsSync(bin)) {
        die(`archive did not contain expected binary at ${bin}`);
    }
    if (process.platform !== 'win32') {
        fs.chmodSync(bin, 0o755);
    }
    try { fs.unlinkSync(archivePath); } catch (_) { /* best-effort cleanup */ }

    say(`installed act v${floor} for ${target}`);
    return bin;
}

async function main() {
    const args = process.argv.slice(2);
    const ensureOnly = args[0] === '--ensure';

    // The SessionStart hook calls `--ensure`; stay silent on success so a
    // routine probe/download isn't surfaced as a hook failure. Info goes to
    // stderr (not stdout) so it can never corrupt the MCP stdio stream in
    // `mcp serve`; errors still speak via die().
    const bin = await ensureBinary({ quiet: ensureOnly });
    if (ensureOnly) return;

    const child = spawn(bin, args, { stdio: 'inherit' });
    child.on('exit', (code, signal) => {
        if (signal) process.kill(process.pid, signal);
        else process.exit(code ?? 0);
    });
    child.on('error', (err) => die(`failed to spawn ${bin}: ${err.message}`));
}

if (require.main === module) {
    main().catch((err) => die(err.stack || err.message));
}

module.exports = { parseVersion, compareVersions, isCompatible, readPluginVersion };
