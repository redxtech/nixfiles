import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { copyFileSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { test } from "node:test";
import { parseArgs } from "node:util";

// exercise installed launchers with an inert Bun stand-in, never the app
const packageRoot = process.env.PITTY_TEST_ROOT;
assert.ok(packageRoot, "Set PITTY_TEST_ROOT to the patched PiTTy package root");

function launch(t, { built = false, resume = false, args = [] } = {}) {
  const directory = mkdtempSync(path.join(tmpdir(), "pitty-launcher-"));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  const root = path.join(directory, "package root");
  const cwd = path.join(directory, "user project");
  mkdirSync(cwd);
  mkdirSync(path.join(root, "bin"), { recursive: true });
  mkdirSync(path.join(root, "node_modules", ".bin"), { recursive: true });
  for (const name of ["pitty.mjs", "pitty-resume.mjs"]) {
    copyFileSync(path.join(packageRoot, "bin", name), path.join(root, "bin", name));
  }
  if (built) {
    mkdirSync(path.join(root, "dist"));
    for (const name of ["index.js", "preload.js", ".pitty-runtime-build-v1"]) {
      writeFileSync(path.join(root, "dist", name), "");
    }
  }
  writeFileSync(
    path.join(root, "node_modules", ".bin", "bun"),
    `#!${process.execPath}
console.log(JSON.stringify({
  args: process.argv.slice(2),
  cwd: process.cwd(),
  appRoot: process.env.PITTY_APP_ROOT,
  noUpdate: process.env.PITTY_NO_UPDATE_CHECK,
}));
`,
    { mode: 0o755 },
  );
  const result = spawnSync(
    process.execPath,
    [path.join(root, "bin", resume ? "pitty-resume.mjs" : "pitty.mjs"), ...args],
    {
      cwd,
      encoding: "utf8",
      env: { HOME: directory, PITTY_NO_UPDATE_CHECK: "1" },
      timeout: 10000,
    },
  );
  assert.ifError(result.error);
  assert.equal(result.status, 0, result.stderr);
  const invocation = JSON.parse(result.stdout);
  assert.equal(invocation.cwd, root, "Bun must resolve JSX configuration at the package root");
  assert.equal(invocation.appRoot, root);
  assert.equal(invocation.noUpdate, "1");
  const runtime = built ? "dist" : "src";
  assert.deepEqual(invocation.args.slice(0, 3), [
    "run",
    `--preload=${path.join(root, runtime, built ? "preload.js" : "preload.ts")}`,
    path.join(root, runtime, built ? "index.js" : "index.tsx"),
  ]);
  return { args: invocation.args.slice(3), cwd };
}

test("source launcher resolves JSX at package root and passes the caller's cwd", (t) => {
  const invocation = launch(t, { args: ["--model", "test-model"] });
  assert.deepEqual(invocation.args, ["--cwd", invocation.cwd, "--model", "test-model"]);
});

test("explicit cwd overrides the injected caller cwd", (t) => {
  const invocation = launch(t, { args: ["--cwd", "/explicit/project"] });
  const parsed = parseArgs({ args: invocation.args, options: { cwd: { type: "string" } } });
  assert.equal(parsed.values.cwd, "/explicit/project");
});

test("built-runtime selection retains the caller's cwd", (t) => {
  const invocation = launch(t, { built: true });
  assert.deepEqual(invocation.args, ["--cwd", invocation.cwd]);
});

test("resume launcher forwards the session picker and caller's cwd", (t) => {
  const invocation = launch(t, { resume: true, args: ["--model", "test-model"] });
  assert.deepEqual(invocation.args, [
    "--cwd", invocation.cwd, "--session-picker", "--model", "test-model",
  ]);
});
