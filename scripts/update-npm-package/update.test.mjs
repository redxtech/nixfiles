import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';
import { updatePackage } from './update.mjs';

const hash = `sha256-${'A'.repeat(43)}=`;
const metadata = {
  name: 'example-cli',
  version: '2.0.0',
  type: 'module',
  bin: { example: 'bin/example.mjs' },
  exports: { '.': './dist/index.mjs' },
  dependencies: { yaml: '^2.9.1', addressparser: '^1.0.1' },
  optionalDependencies: { optional: '^1.0.0' },
  peerDependencies: { peer: '^1.0.0' },
  peerDependenciesMeta: { peer: { optional: true } },
  overrides: { yaml: '$yaml' },
  scripts: { postinstall: 'do-not-run' },
  devDependencies: { typescript: '*' },
  dist: { tarball: 'https://registry.npmjs.org/example-cli/-/example-cli-2.0.0.tgz' },
};

function fixture(t) {
  const directory = mkdtempSync(join(tmpdir(), 'test-update-npm-'));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  writeFileSync(join(directory, 'package.nix'), `{
  version = "1.0.0";
  hash = "${hash}";
  npmDepsHash = "${hash}";
}\n`);
  writeFileSync(join(directory, 'package.json'), JSON.stringify({ name: metadata.name, version: '1.0.0' }));
  writeFileSync(join(directory, 'package-lock.json'), '{"lockfileVersion":3,"packages":{}}\n');
  return directory;
}

function contents(directory) {
  return ['package.nix', 'package.json', 'package-lock.json'].map(file => readFileSync(join(directory, file), 'utf8'));
}

function fakeTools(release = metadata) {
  const calls = [];
  return {
    calls,
    fetchMetadata: async name => {
      assert.equal(name, metadata.name);
      return structuredClone(release);
    },
    run(command, args, options) {
      calls.push({ command, args, options });
      if (command === 'npm') {
        assert.ok(args.includes('--ignore-scripts'));
        assert.ok(args.includes('--package-lock-only'));
        const manifest = JSON.parse(readFileSync(join(options.cwd, 'package.json'), 'utf8'));
        manifest.dependencies = Object.fromEntries(Object.entries(manifest.dependencies).sort(([left], [right]) => left.localeCompare(right)));
        writeFileSync(join(options.cwd, 'package-lock.json'), JSON.stringify({ lockfileVersion: 3, packages: { '': manifest } }));
        return '';
      }
      if (command === 'nix') return JSON.stringify({ hash });
      assert.equal(command, 'prefetch-npm-deps');
      assert.equal(options.env.NPM_FETCHER_VERSION, '2');
      return hash;
    },
  };
}

test('synchronizes published runtime metadata without development or lifecycle scripts', async t => {
  const directory = fixture(t);
  const tools = fakeTools();
  await updatePackage(directory, metadata.name, tools);
  const manifest = JSON.parse(readFileSync(join(directory, 'package.json'), 'utf8'));
  for (const field of ['dependencies', 'optionalDependencies', 'peerDependencies', 'peerDependenciesMeta', 'overrides', 'exports', 'bin']) {
    assert.deepEqual(manifest[field], metadata[field]);
  }
  assert.equal(manifest.version, metadata.version);
  for (const field of ['scripts', 'devDependencies', 'dist']) assert.equal(manifest[field], undefined);
  assert.match(readFileSync(join(directory, 'package.nix'), 'utf8'), /version = "2.0.0";/);
  assert.equal(tools.calls.length, 3);
  assert.equal(readdirSync(directory).length, 3);
});

test('does not resolve dependencies again when the release and runtime metadata are unchanged', async t => {
  const directory = fixture(t);
  const tools = fakeTools();
  await updatePackage(directory, metadata.name, tools);
  const before = contents(directory);
  tools.calls.length = 0;
  await updatePackage(directory, metadata.name, tools);
  assert.deepEqual(contents(directory), before);
  assert.equal(tools.calls.length, 0);
});

test('repairs stale runtime metadata even when the package version already matches', async t => {
  const directory = fixture(t);
  const file = join(directory, 'package.nix');
  writeFileSync(file, readFileSync(file, 'utf8').replace('1.0.0', '2.0.0'));
  const tools = fakeTools();
  await updatePackage(directory, metadata.name, tools);
  assert.deepEqual(JSON.parse(readFileSync(join(directory, 'package.json'), 'utf8')).dependencies, metadata.dependencies);
  assert.equal(tools.calls.length, 3);
});

test('preserves repository files and removes temporary files when prefetch fails', async t => {
  const directory = fixture(t);
  const before = contents(directory);
  const tools = fakeTools();
  const run = tools.run.bind(tools);
  let temporary;
  tools.run = (command, args, options) => {
    if (command === 'npm') temporary = options.cwd;
    if (command === 'prefetch-npm-deps') throw new Error('prefetch failed');
    return run(command, args, options);
  };
  await assert.rejects(updatePackage(directory, metadata.name, tools), /prefetch failed/);
  assert.deepEqual(contents(directory), before);
  assert.throws(() => readdirSync(temporary), { code: 'ENOENT' });
});

test('rejects unexpected package names and tarball hosts before running tools', async t => {
  for (const changes of [{ name: 'wrong' }, { dist: { tarball: 'https://example.org/package.tgz' } }, { version: '2.0.0${evil}' }]) {
    const directory = fixture(t);
    const before = contents(directory);
    const tools = fakeTools({ ...metadata, ...changes });
    await assert.rejects(updatePackage(directory, metadata.name, tools));
    assert.deepEqual(contents(directory), before);
    assert.equal(tools.calls.length, 0);
  }
});

test('rejects duplicate Nix fields and invalid hashes without writing files', async t => {
  for (const invalidHash of [false, true]) {
    const directory = fixture(t);
    if (!invalidHash) {
      const file = join(directory, 'package.nix');
      writeFileSync(file, readFileSync(file, 'utf8') + '  version = "duplicate";\n');
    }
    const before = contents(directory);
    const tools = fakeTools();
    const run = tools.run.bind(tools);
    tools.run = (command, args, options) => command === 'nix' && invalidHash ? '{"hash":"${evil}"}' : run(command, args, options);
    await assert.rejects(updatePackage(directory, metadata.name, tools));
    assert.deepEqual(contents(directory), before);
  }
});

test('does not overwrite edits made while the updater downloads dependencies', async t => {
  const directory = fixture(t);
  const tools = fakeTools();
  const run = tools.run.bind(tools);
  tools.run = (command, args, options) => {
    if (command === 'prefetch-npm-deps') writeFileSync(join(directory, 'package.json'), 'concurrent edit\n');
    return run(command, args, options);
  };
  await assert.rejects(updatePackage(directory, metadata.name, tools), /changed during/);
  assert.equal(readFileSync(join(directory, 'package.json'), 'utf8'), 'concurrent edit\n');
  assert.match(readFileSync(join(directory, 'package.nix'), 'utf8'), /version = "1.0.0";/);
});
