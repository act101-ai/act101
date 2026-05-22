'use strict';

// Unit tests for the act plugin launcher's version-compatibility logic.
// Run with: node --test plugin/test/
//
// The launcher reuses an `act` binary found on PATH (the self-updating
// shell install) instead of downloading its own pinned copy, as long as
// that binary satisfies the plugin's contract. The contract is stable
// within a major version, so the pinned plugin version is a *floor*, not
// an exact target: reuse iff same major AND >= floor.

const { test } = require('node:test');
const assert = require('node:assert/strict');

const { parseVersion, compareVersions, isCompatible } = require('../bin/act.js');

test('parseVersion extracts the semver triple', () => {
    assert.deepEqual(parseVersion('1.0.19'), [1, 0, 19]);
    assert.deepEqual(parseVersion('act 2.13.4'), [2, 13, 4]);
    assert.equal(parseVersion('not-a-version'), null);
    assert.equal(parseVersion(''), null);
});

test('compareVersions orders by major, minor, patch', () => {
    assert.equal(compareVersions([1, 0, 17], [1, 0, 19]), -1);
    assert.equal(compareVersions([1, 0, 19], [1, 0, 17]), 1);
    assert.equal(compareVersions([1, 0, 19], [1, 0, 19]), 0);
    assert.equal(compareVersions([1, 2, 0], [1, 1, 9]), 1);
    assert.equal(compareVersions([2, 0, 0], [1, 9, 9]), 1);
});

test('isCompatible accepts an exact match', () => {
    assert.equal(isCompatible('1.0.19', '1.0.19'), true);
});

test('isCompatible accepts a newer same-major binary (the self-update case)', () => {
    assert.equal(isCompatible('1.0.19', '1.0.17'), true); // patch bump
    assert.equal(isCompatible('1.2.0', '1.0.17'), true);  // minor bump
});

test('isCompatible rejects a binary older than the floor', () => {
    assert.equal(isCompatible('1.0.16', '1.0.17'), false);
    assert.equal(isCompatible('1.0.0', '1.2.0'), false);
});

test('isCompatible rejects a different major (contract may have moved)', () => {
    assert.equal(isCompatible('2.0.0', '1.0.17'), false); // newer major
    assert.equal(isCompatible('0.9.0', '1.0.17'), false); // older major
});

test('isCompatible rejects unparseable versions', () => {
    assert.equal(isCompatible('garbage', '1.0.17'), false);
    assert.equal(isCompatible('1.0.19', 'garbage'), false);
});

const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { readPluginVersion } = require('../bin/act.js');

function tmpPluginRoot(manifestDir, version) {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), 'act-plugin-'));
    const dir = path.join(root, manifestDir);
    fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(path.join(dir, 'plugin.json'), JSON.stringify({ version }));
    return root;
}

test('readPluginVersion reads a .cursor-plugin manifest', () => {
    const root = tmpPluginRoot('.cursor-plugin', '2.3.4');
    assert.equal(readPluginVersion(root), '2.3.4');
});

test('readPluginVersion reads a .codex-plugin manifest', () => {
    const root = tmpPluginRoot('.codex-plugin', '1.2.3');
    assert.equal(readPluginVersion(root), '1.2.3');
});

test('readPluginVersion reads a .claude-plugin manifest', () => {
    const root = tmpPluginRoot('.claude-plugin', '1.0.19');
    assert.equal(readPluginVersion(root), '1.0.19');
});

test('readPluginVersion prefers .cursor-plugin when several manifests exist', () => {
    const root = tmpPluginRoot('.cursor-plugin', '9.9.9');
    const codex = path.join(root, '.codex-plugin');
    fs.mkdirSync(codex, { recursive: true });
    fs.writeFileSync(path.join(codex, 'plugin.json'), JSON.stringify({ version: '1.1.1' }));
    assert.equal(readPluginVersion(root), '9.9.9');
});
