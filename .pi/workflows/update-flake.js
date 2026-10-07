// checkpoint each settled child so continuations reuse evidence rather than repeat mutations
if (typeof state === "undefined") throw new Error("An update mission is required.");
if (!Array.isArray(args.steps) || args.steps.length > 64) throw new Error("Supply at most 64 bounded steps.");
if (![1, 2].includes(args.concurrency)) throw new Error("Build admission must allow one or two children.");
const keys = new Set(args.steps.map(step => step.key));
if (keys.size !== args.steps.length) throw new Error("Step keys must be unique.");
for (const step of args.steps) {
  if (!/^[A-Za-z0-9_-]{1,64}$/.test(step.key) || typeof step.task !== "string" || !step.task || step.task.length > 1024 || !step.label || !step.output || !step.model || typeof step.exclusive !== "boolean") {
    throw new Error("Each step needs a key, task, label, output, and exact model.");
  }
  if (!Array.isArray(step.deps) || step.deps.some(key => !keys.has(key) || key === step.key)) {
    throw new Error("Step dependencies must refer to other supplied keys.");
  }
}
const reachable = new Set();
for (let pass = 0; pass < args.steps.length; pass++) {
  for (const step of args.steps) if (step.deps.every(key => reachable.has(key))) reachable.add(step.key);
}
if (reachable.size !== keys.size) throw new Error("Step dependencies contain a cycle.");
const previous = (await state.get("update-results")) ?? {};
const saved = Object.fromEntries(args.steps.filter(step => previous[step.key]).map(step => [step.key, previous[step.key]]));
const results = {};
for (const step of args.steps) {
  const prior = saved[step.key];
  // stable keys alone cannot authorize reuse after the source plan or child contract changes
  if (prior?.signature === JSON.stringify(step) && prior.ok && prior.verdict === "complete") results[step.key] = prior;
}
const waiting = args.steps.filter(step => !results[step.key]);
let pending = [];
let infrastructureFailure = false;

function launch(step) {
  const params = {
    agent: "delegate", label: step.label, model: step.model, task: step.task,
    context: "fresh", worktree: false, output: step.output, outputMode: "file-only",
    timeoutMs: 86400000, toolTimeoutMs: 43200000,
    acceptance: { level: "none", reason: "Parent-scoped runner checks preserve external user index changes." },
    outputSchema: {
      type: "object", additionalProperties: false,
      required: ["verdict", "evidenceRef"],
      properties: {
        verdict: { type: "string", enum: ["complete", "blocked", "needs_input", "deferred"] },
        evidenceRef: { type: "string" }
      }
    }
  };
  return runs.run(step.key, params).then(
    result => ({ step, result }),
    error => ({ step, result: { ok: false, error: String(error) } })
  );
}

while (waiting.length || pending.length) {
  if (!infrastructureFailure) {
    for (let index = 0; index < waiting.length && pending.length < args.concurrency;) {
      const step = waiting[index];
      if (!step.deps.every(key => results[key]?.verdict === "complete")) {
        index++;
        continue;
      }
      if ((step.exclusive && pending.length) || pending.some(child => child.step.exclusive)) {
        index++;
        continue;
      }
      waiting.splice(index, 1);
      pending.push({ step, promise: launch(step) });
    }
  }
  if (!pending.length) break;
  const { step, result } = await Promise.race(pending.map(child => child.promise));
  pending = pending.filter(child => child.step.key !== step.key);
  const row = {
    signature: JSON.stringify(step),
    ok: result.ok === true,
    verdict: result.ok === true ? (result.structuredOutput?.verdict ?? "blocked") : "blocked",
    runId: result.runId ?? null,
    evidenceRef: result.structuredOutput?.evidenceRef ?? null,
    outputReference: result.outputReference ?? null,
    error: result.error ?? null
  };
  if (!row.evidenceRef) row.verdict = "blocked";
  results[step.key] = row;
  saved[step.key] = row;
  await state.set("update-results", saved);
  emit({ key: step.key, ...row });
  if (!row.ok) infrastructureFailure = true;
}
const complete = args.steps.every(step => results[step.key]?.verdict === "complete");
const needsInput = Object.values(results).some(result => result.verdict === "needs_input");
return {
  verdict: complete ? "complete" : needsInput ? "needs_input" : "blocked",
  results: Object.fromEntries(Object.entries(results).map(([key, row]) => [key, {
    ok: row.ok, verdict: row.verdict, runId: row.runId, evidenceRef: row.evidenceRef
  }])),
  remainingKeys: waiting.map(step => step.key)
};
