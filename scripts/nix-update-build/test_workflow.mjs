import assert from "node:assert/strict";
import fs from "node:fs";
import test from "node:test";

const source = fs.readFileSync(new URL("../../.pi/workflows/update-flake.js", import.meta.url), "utf8");
const execute = new (Object.getPrototypeOf(async function () {}).constructor)("args", "runs", "state", "emit", source);
const step = (key, deps = [], exclusive = false) => ({
  key, deps, exclusive, label: "Build " + key, model: "openai/openai-sub/gpt-6-luna",
  task: "Read fixture-" + key, output: "/tmp/fixture-" + key
});
const complete = () => ({ ok: true, structuredOutput: { verdict: "complete", evidenceRef: "fixture" } });
function mission() {
  const values = {};
  return { get: async key => values[key], set: async (key, value) => { values[key] = value; }, values };
}

test("JSON-safe emit accepts missing optional child metadata", async () => {
  const emitted = [];
  const result = await execute({ steps: [step("a")], concurrency: 1 }, { run: async () => complete() }, mission(), row => {
    assert.ok(!Object.values(row).includes(undefined));
    emitted.push(JSON.parse(JSON.stringify(row)));
  });
  assert.equal(result.verdict, "complete");
  assert.equal(emitted[0].runId, null);
});

test("mission continuation does not repeat successful update", async () => {
  const state = mission();
  const calls = [];
  const runs = { run: async key => { calls.push(key); return complete(); } };
  const args = { steps: [step("update")], concurrency: 1 };
  await execute(args, runs, state, () => {});
  await execute(args, runs, state, () => {});
  assert.deepEqual(calls, ["update"]);
  await execute({ ...args, steps: [{ ...step("update"), task: "new contract" }] }, runs, state, () => {});
  assert.deepEqual(calls, ["update", "update"]);
});

test("blocked target does not stop an independent sibling", async () => {
  const calls = [];
  const result = await execute(
    { steps: [step("a"), step("b"), step("dependent", ["a"])], concurrency: 2 },
    { run: async key => { calls.push(key); return key === "a" ? { ok: true, structuredOutput: { verdict: "needs_input", evidenceRef: "decision" } } : complete(); } },
    mission(), () => {}
  );
  assert.equal(result.verdict, "needs_input");
  assert.deepEqual(calls, ["a", "b"]);
  assert.deepEqual(result.remainingKeys, ["dependent"]);
});

test("rolling scheduling starts ready work without a wave barrier", async () => {
  let release;
  let slowStarted = false;
  const calls = [];
  const runs = { run: key => {
    calls.push(key);
    if (key === "slow") {
      slowStarted = true;
      return new Promise(resolve => { release = resolve; });
    }
    if (key === "next") {
      assert.ok(slowStarted);
      release(complete());
    }
    return Promise.resolve(complete());
  }};
  const result = await execute(
    { steps: [step("slow"), step("fast"), step("next", ["fast"])], concurrency: 2 },
    runs, mission(), () => {}
  );
  assert.equal(result.verdict, "complete");
  assert.deepEqual(calls, ["slow", "fast", "next"]);
});

test("exclusive step runs alone", async () => {
  let active = 0;
  const runs = { run: async (key) => {
    active++;
    if (key === "heavy") assert.equal(active, 1);
    await Promise.resolve();
    active--;
    return complete();
  }};
  const result = await execute({ steps: [step("heavy", [], true), step("a"), step("b")], concurrency: 2 }, runs, mission(), () => {});
  assert.equal(result.verdict, "complete");
});

test("infrastructure failure drains active work and stops new launches", async () => {
  const calls = [];
  const result = await execute(
    { steps: [step("failure"), step("active"), step("new")], concurrency: 2 },
    { run: async key => { calls.push(key); if (key === "failure") throw new Error("fixture launch failure"); return complete(); } },
    mission(), () => {}
  );
  assert.deepEqual(calls, ["failure", "active"]);
  assert.equal(result.verdict, "blocked");
  assert.deepEqual(result.remainingKeys, ["new"]);
});

test("missing verdict cannot count as completion", async () => {
  const result = await execute({ steps: [step("a")], concurrency: 1 }, { run: async () => ({ ok: true }) }, mission(), () => {});
  assert.equal(result.verdict, "blocked");
});

test("missing mission and invalid dependencies fail before dispatch", async () => {
  let calls = 0;
  const runs = { run: async () => { calls++; return complete(); } };
  await assert.rejects(execute({ steps: [step("a")], concurrency: 1 }, runs, undefined, () => {}));
  await assert.rejects(execute({ steps: [step("a", ["unknown"])], concurrency: 1 }, runs, mission(), () => {}));
  await assert.rejects(execute({ steps: [step("a", ["b"]), step("b", ["a"])], concurrency: 1 }, runs, mission(), () => {}));
  assert.equal(calls, 0);
});
