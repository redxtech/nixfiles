import { execFileSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { isDeepStrictEqual } from 'node:util';

const registry = 'https://registry.npmjs.org';
const runtimeFields = [
  'name', 'version', 'description', 'type', 'bin', 'main', 'module', 'types',
  'exports', 'imports', 'files', 'engines', 'license', 'dependencies',
  'optionalDependencies', 'peerDependencies', 'peerDependenciesMeta', 'overrides', 'os', 'cpu',
];

async function fetchMetadata(name) {
  const response = await fetch(`${registry}/${name}/latest`, { signal: AbortSignal.timeout(30000) });
  if (!response.ok) throw new Error(`Cannot get ${name} metadata. HTTP status: ${response.status}`);
  return response.json();
}

function run(command, args, options = {}) {
  return execFileSync(command, args, {
    encoding: 'utf8',
    timeout: 600000,
    maxBuffer: 10 * 1024 * 1024,
    ...options,
    env: { ...process.env, ...options.env },
  }).trim();
}

function replaceField(text, name, value) {
  const pattern = new RegExp(`^(\\s*${name} = ")[^"]+(";)$`, 'gm');
  if ([...text.matchAll(pattern)].length !== 1) throw new Error(`Expected one ${name} assignment`);
  const valid = name === 'version'
    ? /^[0-9]+\.[0-9]+\.[0-9]+(?:[-+][0-9A-Za-z.-]+)?$/.test(value)
    : /^sha256-[A-Za-z0-9+/]{43}=$/.test(value);
  if (!valid) throw new Error(`Invalid ${name} value`);
  return text.replace(pattern, (_, prefix, suffix) => `${prefix}${value}${suffix}`);
}

export async function updatePackage(directory, name, tools = { fetchMetadata, run }) {
  if (!/^[a-z0-9][a-z0-9-]*$/.test(name)) throw new Error('Invalid npm package name');
  const files = ['package.nix', 'package.json', 'package-lock.json'].map(file => join(directory, file));
  const originals = files.map(file => readFileSync(file, 'utf8'));
  const metadata = await tools.fetchMetadata(name);
  if (metadata.name !== name || !/^[0-9]+\.[0-9]+\.[0-9]+(?:[-+][0-9A-Za-z.-]+)?$/.test(metadata.version)) {
    throw new Error('Invalid npm release metadata');
  }
  const tarball = `${registry}/${name}/-/${name}-${metadata.version}.tgz`;
  if (metadata.dist?.tarball !== tarball) throw new Error('Unexpected npm tarball URL');
  let packageText = replaceField(originals[0], 'version', metadata.version);
  const manifest = Object.fromEntries(runtimeFields.filter(field => Object.hasOwn(metadata, field)).map(field => [field, metadata[field]]));
  const manifestText = JSON.stringify(manifest, null, 2) + '\n';
  const lock = JSON.parse(originals[2]);
  const root = lock.packages?.[''];
  const lockMatches = root?.name === name && root?.version === metadata.version
    && ['dependencies', 'optionalDependencies', 'peerDependencies', 'peerDependenciesMeta']
      .every(field => isDeepStrictEqual(root[field], manifest[field]));
  if (packageText === originals[0] && manifestText === originals[1] && lockMatches) {
    return `${name} is already up to date`;
  }

  const temporary = mkdtempSync(join(tmpdir(), `update-${name}-`));
  try {
    writeFileSync(join(temporary, 'package.json'), manifestText);
    const generatedLock = join(temporary, 'package-lock.json');
    tools.run('npm', ['install', '--package-lock-only', '--ignore-scripts', '--no-audit', '--no-fund'], {
      cwd: temporary,
      env: { npm_config_cache: join(temporary, 'npm-cache') },
    });
    const lockText = readFileSync(generatedLock, 'utf8');
    const sourceHash = JSON.parse(tools.run('nix', ['store', 'prefetch-file', '--json', tarball])).hash;
    const dependencyHash = tools.run('prefetch-npm-deps', [generatedLock], { env: { NPM_FETCHER_VERSION: '2' } });
    packageText = replaceField(packageText, 'hash', sourceHash);
    packageText = replaceField(packageText, 'npmDepsHash', dependencyHash);
    if (files.some((file, index) => readFileSync(file, 'utf8') !== originals[index])) {
      throw new Error('Package files changed during the update');
    }
    // finish downloads before changing any repository file
    const updated = [packageText, manifestText, lockText];
    try {
      files.forEach((file, index) => writeFileSync(file, updated[index]));
    } catch (error) {
      files.forEach((file, index) => writeFileSync(file, originals[index]));
      throw error;
    }
    return `Updated ${name} to ${metadata.version}`;
  } finally {
    rmSync(temporary, { recursive: true, force: true });
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  if (process.argv.length !== 4) throw new Error('Usage: update-npm-package DIRECTORY NAME');
  console.log(await updatePackage(resolve(process.argv[2]), process.argv[3]));
}
