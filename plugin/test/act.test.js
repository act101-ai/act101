'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const pluginRoot = path.resolve(__dirname, '..');
const repoRoot = path.resolve(pluginRoot, '..');

function readJson(relativePath) {
    return JSON.parse(fs.readFileSync(path.join(repoRoot, relativePath), 'utf8'));
}

function readText(relativePath) {
    return fs.readFileSync(path.join(repoRoot, relativePath), 'utf8');
}

function firstTomlVersion(relativePath) {
    const match = /^version = "([^"]+)"/m.exec(readText(relativePath));
    assert.ok(match, `${relativePath} must contain a version`);
    return match[1];
}

function workspaceVersion() {
    return firstTomlVersion('Cargo.toml');
}

function marketplaceVersion(relativePath) {
    const entry = readJson(relativePath).plugins.find((plugin) => plugin.name === 'act101');
    assert.ok(entry, `${relativePath} must contain the act101 plugin entry`);
    return entry.version;
}

function assertDirectActMcpManifest(relativePath) {
    const server = readJson(relativePath).mcpServers.act101;

    assert.equal(server.command, 'act');
    assert.deepEqual(server.args, ['mcp', 'serve']);
    assert.equal(server.env.ACT_LOG_LEVEL, 'warn');
    assert.doesNotMatch(
        JSON.stringify(server),
        /node|bin\/act\.js|CLAUDE_PLUGIN_ROOT|CURSOR_PLUGIN_ROOT/,
    );
}

test('plugin and Zed versions match the workspace version', () => {
    const version = workspaceVersion();
    const versionPaths = [
        'plugin/.claude-plugin/plugin.json',
        'plugin/.codex-plugin/plugin.json',
        'plugin/.cursor-plugin/plugin.json',
    ];

    for (const relativePath of versionPaths) {
        assert.equal(readJson(relativePath).version, version, relativePath);
    }

    assert.equal(marketplaceVersion('.claude-plugin/marketplace.json'), version);
    assert.equal(marketplaceVersion('.codex-plugin/marketplace.json'), version);
    assert.equal(marketplaceVersion('.cursor-plugin/marketplace.json'), version);
    assert.equal(firstTomlVersion('zed-extension/extension.toml'), version);
    assert.equal(firstTomlVersion('zed-extension/Cargo.toml'), version);
});

test('host MCP manifests launch the installed act binary directly', () => {
    assertDirectActMcpManifest('plugin/.codex-plugin/mcp.json');
    assertDirectActMcpManifest('plugin/.cursor-plugin/mcp.json');
    assertDirectActMcpManifest('plugin/.mcp.json');
});

test('host plugin manifests do not invoke wrapper hooks', () => {
    for (const relativePath of [
        'plugin/.claude-plugin/plugin.json',
        'plugin/.codex-plugin/plugin.json',
        'plugin/.cursor-plugin/plugin.json',
    ]) {
        const text = readText(relativePath);
        JSON.parse(text);
        assert.doesNotMatch(text, /bin\/act\.js|CLAUDE_PLUGIN_ROOT|CURSOR_PLUGIN_ROOT/);
    }
});

test('legacy Node launcher is not shipped in the plugin payload', () => {
    assert.equal(fs.existsSync(path.join(pluginRoot, 'bin', 'act.js')), false);
});

test('Zed extension launches PATH act and does not download or cache a binary', () => {
    const source = readText('zed-extension/src/lib.rs');

    assert.match(source, /command:\s*"act"\.to_string\(\)/);
    assert.match(source, /"mcp"\.to_string\(\)/);
    assert.match(source, /"serve"\.to_string\(\)/);
    assert.doesNotMatch(
        source,
        /latest_github_release|download_file|download_url|DownloadedFileType|cached_binary|make_file_executable/,
    );
});
