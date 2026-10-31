import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import { updatePackage } from './update.mjs';

const originalPackage = readFileSync(new URL('./package.nix', import.meta.url), 'utf8');
const originalDeps = readFileSync(new URL('./deps.json', import.meta.url), 'utf8');
const currentVersion = originalPackage.match(/pname = "sysdvr";\s+version = "([^"]+)";/)[1];
const currentRevision = originalPackage.match(/sysdvrRev = "([^"]+)";/)[1];
const nextRevision = 'a'.repeat(40);

function fixture(t, { version = '99.0', revision = nextRevision, run } = {}) {
  const directory = mkdtempSync(join(tmpdir(), 'sysdvr-update-test-'));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  const packageFile = join(directory, 'package.nix');
  const depsFile = join(directory, 'deps.json');
  writeFileSync(packageFile, originalPackage);
  writeFileSync(depsFile, originalDeps);
  let runs = 0;
  const tools = {
    async fetchMetadata(path) {
      if (path === 'releases/latest') return { tag_name: `v${version}`, draft: false, prerelease: false };
      assert.equal(path, `commits/v${version}`);
      return { sha: revision };
    },
    async run(command, args, signal) {
      runs++;
      assert.equal(command, 'nix-update');
      assert.deepEqual(args, ['--flake', '--version=skip', 'sysdvr']);
      const candidate = readFileSync(packageFile, 'utf8');
      assert.ok(candidate.includes(`version = "${version}";`));
      assert.ok(candidate.includes(`sysdvrRev = "${revision}";`));
      await run?.({ packageFile, depsFile, candidate, signal });
    },
  };
  return {
    directory, packageFile, depsFile, tools,
    runs: () => runs,
    assertUnchanged() {
      assert.equal(readFileSync(packageFile, 'utf8'), originalPackage);
      assert.equal(readFileSync(depsFile, 'utf8'), originalDeps);
    },
  };
}

test('coordinates release, exact commit, source hash and regenerated dependencies without changing native pins', async t => {
  const nextDeps = [{ pname: 'Example', version: '2.0', hash: 'sha256-example' }];
  const f = fixture(t, { run({ packageFile, depsFile, candidate }) {
    writeFileSync(packageFile, candidate.replace(/(tag = "v\$\{finalAttrs.version\}";\s+hash = ")[^"]+/, '$1sha256-new-source'));
    writeFileSync(depsFile, JSON.stringify(nextDeps));
  } });
  await updatePackage(f.directory, f.tools);
  const updated = readFileSync(f.packageFile, 'utf8');
  assert.match(updated, /sysdvrRev = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"/);
  assert.match(updated, /version = "99\.0"/);
  assert.match(updated, /hash = "sha256-new-source"/);
  assert.deepEqual(JSON.parse(readFileSync(f.depsFile, 'utf8')), nextDeps);
  const nativePins = text => text.slice(text.indexOf('cimgui-sdl2-cross ='), text.indexOf('packages.sysdvr ='));
  assert.equal(nativePins(updated), nativePins(originalPackage));
  assert.equal(f.runs(), 1);
});

test('same release refreshes stale BuildID and dependencies rather than skipping', async t => {
  const deps = JSON.parse(originalDeps);
  deps[0].version = '99.0';
  const f = fixture(t, { version: currentVersion, run({ depsFile }) {
    writeFileSync(depsFile, JSON.stringify(deps));
  } });
  await updatePackage(f.directory, f.tools);
  assert.ok(readFileSync(f.packageFile, 'utf8').includes(`sysdvrRev = "${nextRevision}";`));
  assert.deepEqual(JSON.parse(readFileSync(f.depsFile, 'utf8')), deps);
  assert.equal(f.runs(), 1);
});

test('same version refresh is byte-idempotent despite dependency ordering and formatting', async t => {
  const f = fixture(t, { version: currentVersion, revision: currentRevision, run({ depsFile }) {
    writeFileSync(depsFile, JSON.stringify(JSON.parse(originalDeps).reverse()));
  } });
  await updatePackage(f.directory, f.tools);
  await updatePackage(f.directory, f.tools);
  f.assertUnchanged();
  assert.equal(f.runs(), 2);
});

test('helper failure after partial source and dependency edits restores both original files', async t => {
  const f = fixture(t, { run({ packageFile, depsFile }) {
    writeFileSync(packageFile, 'partially updated source');
    writeFileSync(depsFile, '[partial');
    throw new Error('fetch-deps failed');
  } });
  await assert.rejects(updatePackage(f.directory, f.tools), /fetch-deps failed/);
  f.assertUnchanged();
});

test('malformed generated dependency data rolls back both files', async t => {
  const f = fixture(t, { run({ depsFile }) { writeFileSync(depsFile, '{}'); } });
  await assert.rejects(updatePackage(f.directory, f.tools), /Invalid NuGet/);
  f.assertUnchanged();
});

test('tag moving during regeneration rolls back the coordinated update', async t => {
  const f = fixture(t);
  const fetch = f.tools.fetchMetadata;
  f.tools.fetchMetadata = async path => path.startsWith('commits/') && f.runs() > 0
    ? { sha: 'b'.repeat(40) } : fetch(path);
  await assert.rejects(updatePackage(f.directory, f.tools), /tag moved/);
  f.assertUnchanged();
});

test('metadata failure after regeneration rolls back both files', async t => {
  const f = fixture(t);
  const fetch = f.tools.fetchMetadata;
  f.tools.fetchMetadata = async path => {
    if (f.runs() > 0) throw new Error('GitHub unavailable');
    return fetch(path);
  };
  await assert.rejects(updatePackage(f.directory, f.tools), /GitHub unavailable/);
  f.assertUnchanged();
});

test('interruption during helper execution restores both files', async t => {
  const f = fixture(t, { run({ depsFile, signal }) {
    writeFileSync(depsFile, 'partial');
    process.emit('SIGTERM');
    signal.throwIfAborted();
  } });
  await assert.rejects(updatePackage(f.directory, f.tools), /interrupted/);
  f.assertUnchanged();
});

for (const [name, githubToken, ghToken, expectedToken] of [
  ['prefers GITHUB_TOKEN', 'github-token', 'fallback-token', 'github-token'],
  ['uses GH_TOKEN as a fallback', undefined, 'fallback-token', 'fallback-token'],
  ['allows unauthenticated metadata requests', undefined, undefined, undefined],
]) {
  test(name, async t => {
    const f = fixture(t);
    const previous = { GITHUB_TOKEN: process.env.GITHUB_TOKEN, GH_TOKEN: process.env.GH_TOKEN };
    try {
      for (const [key, value] of Object.entries({ GITHUB_TOKEN: githubToken, GH_TOKEN: ghToken })) {
        if (value === undefined) delete process.env[key];
        else process.env[key] = value;
      }
      t.mock.method(globalThis, 'fetch', async (url, options) => {
        assert.equal(url, 'https://api.github.com/repos/exelix11/SysDVR/releases/latest');
        assert.equal(options.headers.Accept, 'application/vnd.github+json');
        assert.equal(options.headers.Authorization, expectedToken ? `Bearer ${expectedToken}` : undefined);
        return { ok: false, status: 503 };
      });
      await assert.rejects(updatePackage(f.directory), /HTTP 503/);
      f.assertUnchanged();
    } finally {
      for (const [key, value] of Object.entries(previous)) {
        if (value === undefined) delete process.env[key];
        else process.env[key] = value;
      }
    }
  });
}

for (const metadata of [
  { tag_name: 'v6.3', draft: true, prerelease: false },
  { tag_name: 'v6.3', draft: false, prerelease: true },
  { tag_name: 'not-a-version', draft: false, prerelease: false },
]) {
  test(`rejects invalid release metadata before editing: ${JSON.stringify(metadata)}`, async t => {
    const f = fixture(t);
    f.tools.fetchMetadata = async () => metadata;
    await assert.rejects(updatePackage(f.directory, f.tools), /stable SysDVR/);
    f.assertUnchanged();
    assert.equal(f.runs(), 0);
  });
}

test('rejects a non-commit revision before editing', async t => {
  const f = fixture(t, { revision: 'master' });
  await assert.rejects(updatePackage(f.directory, f.tools), /Invalid SysDVR tag commit/);
  f.assertUnchanged();
  assert.equal(f.runs(), 0);
});

test('fails closed if the package assignment layout changes', async t => {
  const f = fixture(t);
  const edited = originalPackage.replace('sysdvrRev =', 'otherRev =');
  writeFileSync(f.packageFile, edited);
  await assert.rejects(updatePackage(f.directory, f.tools), /Expected one assignment/);
  assert.equal(readFileSync(f.packageFile, 'utf8'), edited);
  assert.equal(readFileSync(f.depsFile, 'utf8'), originalDeps);
  assert.equal(f.runs(), 0);
});
