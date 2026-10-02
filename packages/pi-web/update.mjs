import { execFileSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const registry = 'https://registry.npmjs.org';
const peerNames = ['@earendil-works/pi-agent-core', '@earendil-works/pi-ai', '@earendil-works/pi-coding-agent'];

async function fetchMetadata(name, version) {
  const response = await fetch(`${registry}/${name}/${version}`, { signal: AbortSignal.timeout(30000) });
  if (!response.ok) throw new Error(`Failed to fetch ${name}@${version}: HTTP ${response.status}`);
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
  if (!/^[a-zA-Z0-9.+/=-]+$/.test(value)) throw new Error(`Invalid ${name} value: ${value}`);
  return text.replace(pattern, (_, prefix, suffix) => `${prefix}${value}${suffix}`);
}

export async function updatePackage(directory, tools = { fetchMetadata, run }) {
  const packageFile = join(directory, 'package.nix');
  const lockFile = join(directory, 'package-lock.json');
  const originalPackage = readFileSync(packageFile, 'utf8');
  const originalLock = readFileSync(lockFile, 'utf8');
  const metadata = await tools.fetchMetadata('@jmfederico/pi-web', 'latest');
  if (metadata.name !== '@jmfederico/pi-web' || !metadata.version || !metadata.dist?.tarball) {
    throw new Error('Invalid Pi Web release metadata');
  }
  if (peerNames.some(name => !metadata.peerDependencies?.[name]) || Object.keys(metadata.peerDependencies).length !== peerNames.length) {
    throw new Error('Expected the three Pi SDK peer requirements');
  }
  if (metadata.dist.tarball !== `${registry}/@jmfederico/pi-web/-/pi-web-${metadata.version}.tgz`) {
    throw new Error('Unexpected Pi Web tarball URL');
  }
  if (originalPackage.includes(`version = "${metadata.version}";`)) return 'Pi Web is already up to date';

  const temporary = mkdtempSync(join(tmpdir(), 'update-pi-web-'));
  try {
    const manifest = structuredClone(metadata);
    delete manifest.scripts;
    delete manifest.devDependencies;
    const manifestFile = join(temporary, 'package.json');
    const generatedLock = join(temporary, 'package-lock.json');
    const install = () => tools.run('npm', ['install', '--package-lock-only', '--ignore-scripts', '--no-audit', '--no-fund'], {
      cwd: temporary,
      env: { npm_config_cache: join(temporary, 'npm-cache') },
    });
    writeFileSync(manifestFile, JSON.stringify(manifest, null, 2) + '\n');
    install();
    let lock = JSON.parse(readFileSync(generatedLock, 'utf8'));
    const piVersion = lock.packages['node_modules/@earendil-works/pi-coding-agent']?.version;
    if (!piVersion || peerNames.some(name => lock.packages[`node_modules/${name}`]?.version !== piVersion)) {
      throw new Error('The resolved Pi SDK packages must have the same version');
    }
    for (const name of Object.keys(manifest.peerDependencies)) manifest.peerDependencies[name] = piVersion;
    writeFileSync(manifestFile, JSON.stringify(manifest, null, 2) + '\n');
    install();
    lock = JSON.parse(readFileSync(generatedLock, 'utf8'));
    // bundled pi packages can omit integrity fields in npm's generated lock
    for (const [path, dependency] of Object.entries(lock.packages)) {
      if (!path || !dependency.resolved || dependency.integrity) continue;
      const name = path.slice(path.lastIndexOf('node_modules/') + 'node_modules/'.length);
      const info = await tools.fetchMetadata(name, dependency.version);
      if (info.dist?.tarball !== dependency.resolved || !info.dist.integrity) throw new Error(`Invalid integrity metadata for ${name}`);
      dependency.integrity = info.dist.integrity;
    }
    const lockText = JSON.stringify(lock, null, 2) + '\n';
    writeFileSync(generatedLock, lockText);
    const sourceHash = JSON.parse(tools.run('nix', ['store', 'prefetch-file', '--json', metadata.dist.tarball])).hash;
    const dependencyHash = tools.run('prefetch-npm-deps', [generatedLock], { env: { NPM_FETCHER_VERSION: '2' } });
    let packageText = replaceField(originalPackage, 'version', metadata.version);
    packageText = replaceField(packageText, 'piVersion', piVersion);
    packageText = replaceField(packageText, 'hash', sourceHash);
    packageText = replaceField(packageText, 'npmDepsHash', dependencyHash);
    if (readFileSync(packageFile, 'utf8') !== originalPackage || readFileSync(lockFile, 'utf8') !== originalLock) {
      throw new Error('Pi Web package files changed during the update');
    }
    // finish all downloads before replacing either repository file
    try {
      writeFileSync(lockFile, lockText);
      writeFileSync(packageFile, packageText);
    } catch (error) {
      writeFileSync(lockFile, originalLock);
      writeFileSync(packageFile, originalPackage);
      throw error;
    }
    return `Updated Pi Web to ${metadata.version} with Pi SDK ${piVersion}. Update the configured Pi package separately if its version differs.`;
  } finally {
    rmSync(temporary, { recursive: true, force: true });
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  console.log(await updatePackage(resolve('packages/pi-web')));
}
