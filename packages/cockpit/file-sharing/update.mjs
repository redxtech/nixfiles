import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const repository = 'https://github.com/45Drives/cockpit-file-sharing';

async function fetchRelease() {
  const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;
  const response = await fetch('https://api.github.com/repos/45Drives/cockpit-file-sharing/releases/latest', {
    signal: AbortSignal.timeout(30000),
    headers: token ? { Authorization: `Bearer ${token}` } : {},
  });
  if (!response.ok) throw new Error(`Cannot get the latest release. HTTP status: ${response.status}`);
  return response.json();
}

function run(command, args) {
  return execFileSync(command, args, { encoding: 'utf8', timeout: 600000, maxBuffer: 1024 * 1024 }).trim();
}

function replaceField(text, name, value) {
  const pattern = new RegExp(`^(\\s*${name} = ")[^"]+(";)$`, 'gm');
  if ([...text.matchAll(pattern)].length !== 1) throw new Error(`Expected one ${name} assignment`);
  return text.replace(pattern, (_, prefix, suffix) => `${prefix}${value}${suffix}`);
}

export async function updatePackage(file, tools = { fetchRelease, run }) {
  const original = readFileSync(file, 'utf8');
  const release = await tools.fetchRelease();
  const version = /^v([0-9]+\.[0-9]+\.[0-9]+(?:-[0-9]+)?)$/.exec(release.tag_name)?.[1];
  if (!version || release.draft || release.prerelease || !Array.isArray(release.assets)) {
    throw new Error('Expected a stable release with assets');
  }
  const assets = release.assets.filter(asset => /^cockpit-file-sharing_[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9]+)?bookworm_all\.deb$/.test(asset.name));
  if (assets.length !== 1) throw new Error('Expected one Bookworm Debian asset');
  const asset = assets[0];
  const packageVersion = asset.name.slice('cockpit-file-sharing_'.length, -'bookworm_all.deb'.length);
  const url = `${repository}/releases/download/${release.tag_name}/${asset.name}`;
  if ((packageVersion !== version && !packageVersion.startsWith(`${version}-`)) || asset.browser_download_url !== url) {
    throw new Error('The Debian asset does not match the release');
  }
  let text = replaceField(original, 'version', version);
  text = replaceField(text, 'url', url);
  const hash = JSON.parse(tools.run('nix', ['store', 'prefetch-file', '--json', url])).hash;
  if (!/^sha256-[A-Za-z0-9+/]{43}=$/.test(hash)) throw new Error('Invalid source hash');
  text = replaceField(text, 'hash', hash);
  if (readFileSync(file, 'utf8') !== original) throw new Error('Package file changed during the update');
  if (text === original) return 'cockpit-file-sharing is already up to date';
  writeFileSync(file, text);
  return `Updated cockpit-file-sharing to ${version}`;
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  console.log(await updatePackage(resolve('packages/cockpit/file-sharing/package.nix')));
}
