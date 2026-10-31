import { spawn } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { isDeepStrictEqual } from 'node:util';
import { pathToFileURL } from 'node:url';

const api = 'https://api.github.com/repos/exelix11/SysDVR';

async function fetchMetadata(path, signal) {
  const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;
  const response = await fetch(`${api}/${path}`, {
    signal: AbortSignal.any([signal, AbortSignal.timeout(30000)]),
    headers: {
      Accept: 'application/vnd.github+json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
  });
  if (!response.ok) throw new Error(`GitHub ${path}: HTTP ${response.status}`);
  return response.json();
}

function run(command, args, signal) {
  signal.throwIfAborted();
  return new Promise((resolve, reject) => {
    // stop the helper's descendants as well before rolling back on interruption
    const child = spawn(command, args, { detached: true, stdio: ['ignore', 'pipe', 'pipe'] });
    child.stdout.pipe(process.stdout);
    child.stderr.pipe(process.stderr);
    const abort = () => {
      if (child.pid) {
        try { process.kill(-child.pid, 'SIGTERM'); } catch (error) {
          if (error.code !== 'ESRCH') throw error;
        }
      }
    };
    signal.addEventListener('abort', abort, { once: true });
    child.on('error', reject);
    child.on('close', (code, killedBy) => {
      signal.removeEventListener('abort', abort);
      if (signal.aborted) reject(signal.reason);
      else if (code !== 0) reject(new Error(`${command} failed (${killedBy ?? code})`));
      else resolve();
    });
  });
}

function replaceOne(text, pattern, value) {
  if ([...text.matchAll(pattern)].length !== 1) throw new Error(`Expected one assignment matching ${pattern}`);
  return text.replace(pattern, (_, prefix, suffix) => `${prefix}${value}${suffix}`);
}

function dependencies(text) {
  const deps = JSON.parse(text);
  if (!Array.isArray(deps) || deps.length === 0 || deps.some(dep =>
    typeof dep.pname !== 'string' || typeof dep.version !== 'string' || typeof dep.hash !== 'string')) {
    throw new Error('Invalid NuGet dependency data');
  }
  return deps.sort((a, b) => `${a.pname}/${a.version}`.localeCompare(`${b.pname}/${b.version}`));
}

export async function updatePackage(directory, tools = { fetchMetadata, run }) {
  const packageFile = join(directory, 'package.nix');
  const depsFile = join(directory, 'deps.json');
  const originalPackage = readFileSync(packageFile, 'utf8');
  const originalDeps = readFileSync(depsFile, 'utf8');
  const controller = new AbortController();
  const interrupt = () => controller.abort(new Error('SysDVR update interrupted'));
  process.once('SIGINT', interrupt);
  process.once('SIGTERM', interrupt);
  let changed = false;
  try {
    const release = await tools.fetchMetadata('releases/latest', controller.signal);
    if (release.draft !== false || release.prerelease !== false || !/^v\d+\.\d+(?:\.\d+)?$/.test(release.tag_name)) {
      throw new Error('Expected a stable SysDVR v<version> release');
    }
    const version = release.tag_name.slice(1);
    // the commits endpoint peels annotated tags, while target_commitish can be a branch
    const commitPath = `commits/${release.tag_name}`;
    const { sha } = await tools.fetchMetadata(commitPath, controller.signal);
    if (!/^[0-9a-f]{40}$/.test(sha)) throw new Error('Invalid SysDVR tag commit');
    let updated = replaceOne(originalPackage, /^(\s*sysdvrRev = ")[^"]+(";)$/gm, sha);
    updated = replaceOne(updated, /(packages\.sysdvr = buildDotnetModule \(finalAttrs: \{\s+pname = "sysdvr";\s+version = ")[^"]+(";)/g, version);
    controller.signal.throwIfAborted();
    changed = true;
    writeFileSync(packageFile, updated);
    // skip keeps the coordinated version but refreshes the source hash and
    // buildDotnetModule's fetch-deps even when the release version is unchanged
    await tools.run('nix-update', ['--flake', '--version=skip', 'sysdvr'], controller.signal);
    const current = await tools.fetchMetadata(commitPath, controller.signal);
    if (current.sha !== sha) throw new Error('SysDVR tag moved during the update');
    const generatedDeps = readFileSync(depsFile, 'utf8');
    if (isDeepStrictEqual(dependencies(generatedDeps), dependencies(originalDeps))) {
      writeFileSync(depsFile, originalDeps);
    }
    controller.signal.throwIfAborted();
    return `Verified SysDVR ${version} (${sha}), source hash and NuGet dependencies`;
  } catch (error) {
    if (changed) {
      writeFileSync(packageFile, originalPackage);
      writeFileSync(depsFile, originalDeps);
    }
    throw error;
  } finally {
    process.removeListener('SIGINT', interrupt);
    process.removeListener('SIGTERM', interrupt);
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  console.log(await updatePackage('packages/sysdvr'));
}
