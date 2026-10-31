import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';
import { updatePackage } from './update.mjs';

const filename = 'cockpit-file-sharing_4.6.3-1bookworm_all.deb';
const url = `https://github.com/45Drives/cockpit-file-sharing/releases/download/v4.6.3/${filename}`;
const hash = `sha256-${'A'.repeat(43)}=`;
const release = {
  tag_name: 'v4.6.3',
  draft: false,
  prerelease: false,
  assets: [{ name: filename, browser_download_url: url }],
};

function fixture(t) {
  const directory = mkdtempSync(join(tmpdir(), 'test-update-file-sharing-'));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  const file = join(directory, 'package.nix');
  writeFileSync(file, `{
  version = "4.6.1-2";
  src = {
    url = "https://example.org/old.deb";
    hash = "${hash}";
  };
}\n`);
  return file;
}

function fakeTools(metadata = release) {
  return {
    fetchRelease: async () => structuredClone(metadata),
    run(command, args) {
      assert.equal(command, 'nix');
      assert.equal(args.at(-1), url);
      return JSON.stringify({ hash });
    },
  };
}

test('uses the published asset URL when its Debian revision differs from the release tag', async t => {
  const file = fixture(t);
  await updatePackage(file, fakeTools());
  const text = readFileSync(file, 'utf8');
  assert.ok(text.includes('version = "4.6.3";'));
  assert.ok(text.includes(`url = "${url}";`));
  const before = text;
  await updatePackage(file, fakeTools());
  assert.equal(readFileSync(file, 'utf8'), before);
});

test('rejects missing, ambiguous, mismatched, draft, and prerelease assets', async t => {
  for (const changes of [
    { assets: [] },
    { assets: [...release.assets, ...release.assets] },
    { assets: [{ name: filename, browser_download_url: 'https://example.org/asset.deb' }] },
    { tag_name: 'v9.0.0' },
    { draft: true },
    { prerelease: true },
  ]) {
    const file = fixture(t);
    const before = readFileSync(file, 'utf8');
    await assert.rejects(updatePackage(file, fakeTools({ ...release, ...changes })));
    assert.equal(readFileSync(file, 'utf8'), before);
  }
});

test('preserves the package when prefetch fails or produces an invalid hash', async t => {
  for (const invalidHash of [false, true]) {
    const file = fixture(t);
    const before = readFileSync(file, 'utf8');
    const tools = fakeTools();
    tools.run = () => {
      if (invalidHash) return '{"hash":"${evil}"}';
      throw new Error('download failed');
    };
    await assert.rejects(updatePackage(file, tools));
    assert.equal(readFileSync(file, 'utf8'), before);
  }
});

test('rejects duplicate fields and preserves concurrent edits', async t => {
  const duplicate = fixture(t);
  writeFileSync(duplicate, readFileSync(duplicate, 'utf8') + '  version = "duplicate";\n');
  const before = readFileSync(duplicate, 'utf8');
  await assert.rejects(updatePackage(duplicate, fakeTools()));
  assert.equal(readFileSync(duplicate, 'utf8'), before);

  const concurrent = fixture(t);
  const tools = fakeTools();
  const run = tools.run;
  tools.run = (...args) => {
    writeFileSync(concurrent, 'concurrent edit\n');
    return run(...args);
  };
  await assert.rejects(updatePackage(concurrent, tools), /changed during/);
  assert.equal(readFileSync(concurrent, 'utf8'), 'concurrent edit\n');
});
