import { readFile, writeFile, mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  createAgentSession, createExtensionRuntime, ModelRuntime,
  SessionManager, SettingsManager,
} from "@earendil-works/pi-coding-agent";

export function snapshotTools(files, maxCalls = 40) {
  let calls = 0;
  const result = (value) => {
    if (++calls > maxCalls) throw new Error("The snapshot read limit was reached.");
    return { content: [{ type: "text", text: JSON.stringify(value) }], details: {} };
  };
  return [
    {
      name: "read_source", label: "Read source", description: "Read a bounded range from a snapshot file. Lines are one-based.",
      parameters: {
        type: "object", additionalProperties: false, required: ["path", "line"],
        properties: { path: { type: "string" }, line: { type: "integer", minimum: 1 } },
      },
      execute: async (_id, { path, line }) => {
        if (!Object.hasOwn(files, path) || !Number.isSafeInteger(line) || line < 1) {
          throw new Error("The source path or line is not available.");
        }
        const lines = files[path].split("\n");
        return result({ path, totalLines: lines.length, lines: lines.slice(line - 1, line + 119).map((text, i) => `${line + i}: ${text}`).join("\n").slice(0, 16000) });
      },
    },
    {
      name: "search_source", label: "Search source", description: "Find a literal in snapshot files. Return at most 40 matching lines.",
      parameters: {
        type: "object", additionalProperties: false, required: ["text"],
        properties: { text: { type: "string", minLength: 1, maxLength: 200 } },
      },
      execute: async (_id, { text }) => {
        if (typeof text !== "string" || !text.length || text.length > 200) throw new Error("Invalid search text.");
        const matches = [];
        for (const [path, content] of Object.entries(files)) {
          for (const [index, line] of content.split("\n").entries()) {
            if (line.includes(text)) matches.push({ path, line: index + 1, text: line.slice(0, 300) });
            if (matches.length === 40) return result({ matches, limited: true });
          }
        }
        return result({ matches, limited: false });
      },
    },
  ];
}

export async function diagnose(plan, output, options = {}) {
  if (!plan.eligible) throw new Error("The repair plan is not eligible.");
  const apiKey = options.apiKey ?? process.env.CLIPROXYAPI_REPAIR_KEY;
  if (!apiKey) throw new Error("Set the CLIPROXYAPI_REPAIR_KEY repository secret.");
  const directory = await mkdtemp(join(tmpdir(), "flake-repair-agent-"));
  let session;
  let exceeded = false;
  let aborting = Promise.resolve();
  let timer;
  try {
    const runtime = await ModelRuntime.create({
      authPath: join(directory, "auth.json"), modelsPath: null,
      modelsStorePath: join(directory, "catalog.json"), refreshOnCreate: false, allowModelNetwork: false,
    });
    runtime.registerProvider("quasar-repair", {
      baseUrl: options.baseUrl ?? "https://ai-api.colobus-pirate.ts.net/v1",
      api: "openai-responses",
      models: [{ id: "gpt-6.1-sol", name: "gpt-6.1-sol", reasoning: true, input: ["text"],
        contextWindow: 131072, maxTokens: 8192, cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 } }],
    });
    await runtime.setRuntimeApiKey("quasar-repair", apiKey);
    const model = runtime.getModel("quasar-repair", "gpt-6.1-sol");
    if (!model || model.id !== "gpt-6.1-sol") throw new Error("The configured repair model is unavailable.");
    const systemPrompt = await readFile(new URL("prompt.md", import.meta.url), "utf8");
    const resourceLoader = {
      getExtensions: () => ({ extensions: [], errors: [], runtime: createExtensionRuntime() }),
      getSkills: () => ({ skills: [], diagnostics: [] }), getPrompts: () => ({ prompts: [], diagnostics: [] }),
      getThemes: () => ({ themes: [], diagnostics: [] }), getAgentsFiles: () => ({ agentsFiles: [] }),
      getSystemPrompt: () => systemPrompt, getSystemPromptSource: () => undefined,
      getAppendSystemPrompt: () => [], getAppendSystemPromptSources: () => [],
      extendResources: () => {}, reload: async () => {},
    };
    ({ session } = await createAgentSession({
      cwd: directory, agentDir: directory, modelRuntime: runtime,
      model, thinkingLevel: "medium",
      tools: ["read_source", "search_source"], customTools: snapshotTools(plan.files), resourceLoader,
      sessionManager: SessionManager.inMemory(directory),
      settingsManager: SettingsManager.inMemory({
        compaction: { enabled: false }, retry: { enabled: false, provider: { maxRetries: 0, timeoutMs: 120000 } },
        cacheWarming: "off", enableAnalytics: false, enableInstallTelemetry: false,
      }),
    }));
    const abort = () => {
      exceeded = true;
      aborting = session.abort();
    };
    let turns = 0;
    let tokens = 0;
    session.subscribe((event) => {
      if (event.type === "turn_start" && ++turns > 24) abort();
      if (event.type === "message_end" && event.message.role === "assistant") {
        tokens += event.message.usage?.totalTokens ?? 0;
        if (tokens > 250000) abort();
      }
    });
    timer = setTimeout(abort, 10 * 60 * 1000);
    await session.prompt(JSON.stringify({
      sha: plan.sha, base: plan.base, inputs: plan.inputs,
      files: Object.keys(plan.files),
      failures: plan.failures.map((record) => ({ ...record, phases: Object.fromEntries(
        Object.entries(record.phases).map(([name, phase]) => [name, { ...phase, log: phase.log.slice(-16000) }]),
      ) })),
    }));
    await aborting;
    const last = session.messages.filter((message) => message.role === "assistant").at(-1);
    if (exceeded || !last || last.stopReason !== "stop") throw new Error("The diagnosis did not complete within its limits.");
    const text = session.getLastAssistantText();
    if (!text || Buffer.byteLength(text) > 32768) throw new Error("The diagnosis exceeds the output limit.");
    const proposal = JSON.parse(text);
    if (JSON.stringify(proposal).includes(apiKey)) throw new Error("The diagnosis contains a protected credential.");
    await writeFile(output, JSON.stringify(proposal));
    console.log(`Diagnosis completed in ${turns} turns, ${tokens} reported tokens.`);
  } finally {
    clearTimeout(timer);
    await aborting;
    session?.dispose();
    await rm(directory, { recursive: true, force: true });
  }
}

if (process.argv[1] && import.meta.url === new URL(`file://${process.argv[1]}`).href) {
  try {
    await diagnose(JSON.parse(await readFile(process.argv[2], "utf8")), process.argv[3]);
  } catch {
    console.error("Diagnosis failed. Check the model service, credential, response format, and execution limits.");
    process.exitCode = 1;
  }
}
