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

function readPluginVersion() {
    const manifest = path.join(PLUGIN_ROOT, '.claude-plugin', 'plugin.json');
    const raw = fs.readFileSync(manifest, 'utf8');
    const { version } = JSON.parse(raw);
    if (!version || typeof version !== 'string') {
        die(`plugin.json is missing a version field at ${manifest}`);
    }
    return version;
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

function probePathBinary(expectedVersion) {
    // Look for an `act` already on PATH — the shell installer places one
    // there. If its --version matches the plugin manifest, reuse it.
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
    if (match[1] !== expectedVersion) {
        log(`ignoring ${candidate} (version ${match[1]} != plugin ${expectedVersion})`);
        return null;
    }
    log(`using PATH binary: ${candidate}`);
    return candidate;
}

async function ensureBinary() {
    const version = readPluginVersion();
    const target = detectTarget();
    const bin = binaryPath(version, target);

    if (fs.existsSync(bin)) return bin;

    const onPath = probePathBinary(version);
    if (onPath) return onPath;

    const url = downloadUrl(version, target);
    const destDir = path.dirname(bin);
    fs.mkdirSync(destDir, { recursive: true });

    const archivePath = path.join(destDir, archiveName(target));
    log(`downloading ${url}`);
    await fetchWithRedirects(url, archivePath);

    log(`extracting to ${destDir}`);
    extractArchive(archivePath, destDir);

    if (!fs.existsSync(bin)) {
        die(`archive did not contain expected binary at ${bin}`);
    }
    if (process.platform !== 'win32') {
        fs.chmodSync(bin, 0o755);
    }
    try { fs.unlinkSync(archivePath); } catch (_) { /* best-effort cleanup */ }

    log(`installed act v${version} for ${target}`);
    return bin;
}

async function main() {
    const args = process.argv.slice(2);
    const ensureOnly = args[0] === '--ensure';

    const bin = await ensureBinary();
    if (ensureOnly) return;

    const child = spawn(bin, args, { stdio: 'inherit' });
    child.on('exit', (code, signal) => {
        if (signal) process.kill(process.pid, signal);
        else process.exit(code ?? 0);
    });
    child.on('error', (err) => die(`failed to spawn ${bin}: ${err.message}`));
}

main().catch((err) => die(err.stack || err.message));
