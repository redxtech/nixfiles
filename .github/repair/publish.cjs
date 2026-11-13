const fs = require("node:fs");

const start = "<!-- nixfiles-flake-repair:start -->";
const end = "<!-- nixfiles-flake-repair:end -->";
const shaPattern = /^[0-9a-f]{40}$/;

function requireValue(condition, message) {
  if (!condition) throw new Error(message);
}

function readJson(file, limit = 16 * 1024 * 1024) {
  requireValue(fs.statSync(file).size <= limit, "The report file exceeds the size limit.");
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function optionalJson(file, limit) {
  return fs.existsSync(file) ? readJson(file, limit) : null;
}

function plain(value, limit = 8000) {
  return String(value ?? "").slice(0, limit).replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll("@", "&#64;");
}

function updateBody(body, section) {
  body ??= "";
  const starts = body.split(start).length - 1;
  const ends = body.split(end).length - 1;
  requireValue(starts === ends && starts <= 1, "The PR description has invalid repair markers.");
  const replacement = `${start}\n${section}\n${end}`;
  const result = starts ? body.slice(0, body.indexOf(start)) + replacement + body.slice(body.indexOf(end) + end.length)
    : `${body.trimEnd()}\n\n${replacement}\n`;
  requireValue(result.length <= 60000, "The PR description exceeds the size limit.");
  return result;
}

async function publish({ github, context, core }, env = process.env) {
  const plan = readJson(env.REPAIR_PLAN);
  requireValue(plan.sha === env.BUILD_REF && plan.base === env.BASE_REF && plan.pr === Number(env.REPAIR_PR), "The repair identity does not match the workflow.");
  requireValue(shaPattern.test(plan.sha) && shaPattern.test(plan.base), "Invalid repair source SHA.");
  const repo = context.repo;
  const getPr = async () => (await github.rest.pulls.get({ ...repo, pull_number: plan.pr })).data;
  const verifyPr = (pr, head) => {
    requireValue(pr.state === "open" && pr.head.repo?.full_name === `${repo.owner}/${repo.repo}`
      && pr.base.repo?.full_name === `${repo.owner}/${repo.repo}`
      && pr.head.ref === "automation/update-flake-inputs" && pr.base.ref === env.BASE_BRANCH
      && pr.base.sha === plan.base && pr.head.sha === head,
    "The update PR changed or no longer matches this repair.");
  };
  let pr = await getPr();
  verifyPr(pr, plan.sha);
  // check description ownership before any branch mutation
  updateBody(pr.body, "repair in progress");
  const proposal = optionalJson(env.REPAIR_PROPOSAL, 32768);
  const checked = optionalJson(env.REPAIR_CHECKED, 4096);
  const bundle = optionalJson(env.REPAIR_BUNDLE, 256000);
  let newSha = null;
  if (bundle) {
    requireValue(checked?.allowed === true && bundle.sha === plan.sha && bundle.base === plan.base
      && shaPattern.test(bundle.tree), "The validated bundle does not match.");
    const entries = Object.entries(bundle.files);
    requireValue(entries.length > 0 && entries.length <= 3, "Invalid repair file count.");
    const commit = (await github.rest.git.getCommit({ ...repo, commit_sha: plan.sha })).data;
    const tree = [];
    for (const [file, content] of entries) {
      requireValue(/^(modules\/features\/|packages\/)[A-Za-z0-9_./-]+\.nix$/.test(file)
        && !file.split("/").includes("..") && typeof content === "string"
        && Buffer.byteLength(content) <= 65536, "Invalid repair file.");
      const blob = await github.rest.git.createBlob({ ...repo, content: Buffer.from(content).toString("base64"), encoding: "base64" });
      tree.push({ path: file, mode: "100644", type: "blob", sha: blob.data.sha });
    }
    const created = await github.rest.git.createTree({ ...repo, base_tree: commit.tree.sha, tree });
    requireValue(created.data.sha === bundle.tree, "The published tree differs from the validated tree.");
    const createdCommit = await github.rest.git.createCommit({
      ...repo, message: "fix: resolve flake update compatibility renames", tree: created.data.sha, parents: [plan.sha],
    });
    verifyPr(await getPr(), plan.sha);
    await github.rest.git.updateRef({ ...repo, ref: "heads/automation/update-flake-inputs", sha: createdCommit.data.sha, force: false });
    newSha = createdCommit.data.sha;
    await github.rest.repos.createCommitStatus({
      ...repo, sha: newSha, context: "update-flake / repair-validation", state: "success",
      target_url: `${context.serverUrl}/${repo.owner}/${repo.repo}/actions/runs/${context.runId}`,
      description: "All 8 repaired targets and required baseline builds passed. No uploads were run.",
    });
    core.setOutput("repair-sha", newSha);
  }
  const runUrl = `${context.serverUrl}/${repo.owner}/${repo.repo}/actions/runs/${context.runId}`;
  const heading = newSha ? "verified compatibility repair" : "build failure diagnosis";
  const outcome = newSha
    ? `Committed as \`${newSha}\`. All eight target builds passed for this exact tree. Originally failing targets also passed before the input update. Cache uploads were not rerun. No merge or deployment occurred.`
    : "No source changes were published. Owner review is required. No merge or deployment occurred.";
  const diagnosis = proposal && typeof proposal.summary === "string" && typeof proposal.cause === "string"
    ? `<pre>${plain(proposal.summary, 2000)}\n\n${plain(proposal.cause, 6000)}</pre>`
    : "The model diagnosis is unavailable. Check the model credential, job results, and repair admission report.";
  const edits = newSha ? `<pre>${Object.keys(bundle.files).map((file) => plain(file)).join("\n")}</pre>` : "";
  const section = `### ${heading}\n\n${outcome}\n\nFailed build commit: \`${plan.sha}\`.\n\n${diagnosis}\n\n${edits}\n\n<pre>${plain(checked?.reason ?? plan.reason)}</pre>\n\n[view diagnosis and validation](${runUrl})`;
  pr = await getPr();
  verifyPr(pr, newSha ?? plan.sha);
  await github.rest.pulls.update({ ...repo, pull_number: plan.pr, body: updateBody(pr.body, section) });
  const marker = `<!-- nixfiles-flake-repair:${context.runId}:${env.RUN_ATTEMPT} -->`;
  const comments = await github.paginate(github.rest.issues.listComments, { ...repo, issue_number: plan.pr, per_page: 100 });
  const previous = comments.find((comment) => comment.user?.type === "Bot" && comment.body?.includes(marker));
  const body = `${marker}\n${section}`;
  if (previous) await github.rest.issues.updateComment({ ...repo, comment_id: previous.id, body });
  else await github.rest.issues.createComment({ ...repo, issue_number: plan.pr, body });
  await core.summary.addHeading(heading, 2).addRaw(outcome).addLink("view workflow run", runUrl).write();
}

module.exports = publish;
module.exports.updateBody = updateBody;
module.exports.plain = plain;
