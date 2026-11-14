const fs = require("node:fs");
const path = require("node:path");

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

function plain(value, limit = 8000) {
  return String(value ?? "").slice(0, limit).replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll("@", "&#64;");
}

function updateBody(body, section) {
  body ??= "";
  const starts = body.split(start).length - 1;
  const ends = body.split(end).length - 1;
  requireValue(starts === ends && starts <= 1 && (!starts || body.indexOf(start) < body.indexOf(end)),
    "The PR description has invalid repair markers.");
  const replacement = `${start}\n${section}\n${end}`;
  const result = starts ? body.slice(0, body.indexOf(start)) + replacement + body.slice(body.indexOf(end) + end.length)
    : `${body.trimEnd()}\n\n${replacement}\n`;
  requireValue(result.length <= 60000, "The PR description exceeds the size limit.");
  return result;
}

function renderReport(report, compact = false) {
  const publication = report.publication;
  const outcome = publication.status === "published"
    ? `Published repair commit: \`${publication.commit}\`. All eight builds and the required baselines passed for its exact tree.`
    : publication.status === "publication-uncertain"
      ? "The branch update has an uncertain result. Owner review is required."
      : "No source changes were published. Owner review is required.";
  const sections = ["### automated remediation report", outcome,
    `Failed build commit: \`${report.sha}\`. Baseline: \`${report.base}\`.`,
    "Cache uploads were not rerun. No merge or deployment occurred.",
    `<pre>${plain(publication.reason ?? report.admission, 2000)}</pre>`];
  if (report.jobs) sections.push(`<pre>${Object.entries(report.jobs).map(([name, job]) => `${plain(name, 100)}: ${plain(job.result, 30)}`).join("\n")}</pre>`);
  for (const attempt of report.attempts) {
    const proposal = attempt.proposal;
    const applied = publication.status === "published" && report.selectedAttempt === attempt.attempt;
    sections.push(`#### attempt ${attempt.attempt}: ${applied ? "published" : "not published"}`,
      `<pre>${plain(attempt.reason, 2000)}</pre>`);
    if (proposal) sections.push(`<pre>${plain(proposal.summary, 2000)}\n\n${plain(proposal.cause, compact ? 2000 : 6000)}</pre>`);
    if (attempt.error) sections.push(`<pre>${plain(attempt.error.stage, 100)}: ${plain(attempt.error.message, 2000)}</pre>`);
    sections.push(`<pre>Policy: ${attempt.policy.allowed ? "passed" : "not permitted"}\n${plain(attempt.policy.reason, 2000)}</pre>`);
    if (attempt.changes.length) sections.push("Proposed changes:", `<pre>${attempt.changes.map(edit =>
      `${plain(edit.path, 500)}:${edit.line} (${plain(edit.kind, 100)})`).join("\n")}</pre>`);
    if (attempt.diff) sections.push(`<details><summary>${applied ? "Published" : "Proposed, not published"} diff</summary>\n\n<pre>${plain(attempt.diff, compact ? 4000 : 600000)}${compact && attempt.diff.length > 4000 ? "\n[full diff is in the run artifact]" : ""}</pre>\n\n</details>`);
    sections.push(attempt.validation.length ? `<pre>${attempt.validation.map(record =>
      `${plain(record.target, 250)}: baseline=${plain(record.baseline, 30)}, repaired=${plain(record.repaired, 30)}, complete=${record.complete === true}\n${plain(record.reason, compact ? 300 : 2000)}`).join("\n\n")}</pre>` : "No target validation evidence is available for this attempt.");
  }
  if (publication.error) sections.push(`<pre>Publication error: ${plain(publication.error, 2000)}</pre>`);
  if (!compact) sections.push(`PR description updated: ${publication.prUpdated === true}. Bot comment updated: ${publication.commentUpdated === true}.`);
  sections.push(`[view the run and the repair-report artifact](${report.runUrl})`);
  return sections.join("\n\n");
}

function saveReport(file, report) {
  fs.writeFileSync(file, JSON.stringify(report, null, 2));
  fs.writeFileSync(path.join(path.dirname(file), "report.md"), renderReport(report));
}

async function publish({ github, context, core }, env = process.env) {
  const plan = readJson(env.REPAIR_PLAN);
  const report = readJson(env.REPAIR_REPORT);
  const repo = context.repo;
  report.runUrl = `${context.serverUrl}/${repo.owner}/${repo.repo}/actions/runs/${context.runId}`;
  const publication = report.publication;
  const getPr = async () => (await github.rest.pulls.get({ ...repo, pull_number: plan.pr })).data;
  const verifyPr = (pr, head) => {
    requireValue(pr.state === "open" && pr.head.repo?.full_name === `${repo.owner}/${repo.repo}`
      && pr.base.repo?.full_name === `${repo.owner}/${repo.repo}`
      && pr.head.ref === "automation/update-flake-inputs" && pr.base.ref === env.BASE_BRANCH
      && pr.base.sha === plan.base && pr.head.sha === head,
    "The update PR changed or no longer matches this repair.");
  };
  let newSha = null;
  try {
    requireValue(plan.sha === env.BUILD_REF && plan.base === env.BASE_REF && plan.pr === Number(env.REPAIR_PR),
      "The repair identity does not match the workflow.");
    requireValue(shaPattern.test(plan.sha) && shaPattern.test(plan.base), "Invalid repair source SHA.");
    requireValue(report.sha === plan.sha && report.base === plan.base && report.pr === plan.pr,
      "The action report does not match the repair.");
    let pr = await getPr();
    verifyPr(pr, plan.sha);
    // check description ownership and size before any branch mutation
    updateBody(pr.body, renderReport(report, true) + " ".repeat(2048));
    const bundle = fs.existsSync(env.REPAIR_BUNDLE) ? readJson(env.REPAIR_BUNDLE, 2 * 1024 * 1024) : null;
    if (bundle) {
      const selected = report.attempts.find(attempt => attempt.attempt === report.selectedAttempt);
      requireValue(selected?.policy.allowed === true && bundle.attempt === report.selectedAttempt
        && bundle.sha === plan.sha && bundle.base === plan.base && shaPattern.test(bundle.tree),
      "The validated bundle does not match.");
      const entries = Object.entries(bundle.files);
      requireValue(entries.length > 0 && entries.length <= 3, "Invalid repair file count.");
      const commit = (await github.rest.git.getCommit({ ...repo, commit_sha: plan.sha })).data;
      const tree = [];
      for (const [file, content] of entries) {
        requireValue(/^(?:modules\/features\/[A-Za-z0-9_./-]+\.nix|packages\/[A-Za-z0-9_./-]+\.(?:nix|patch))$/.test(file)
          && !file.split("/").includes("..") && typeof content === "string"
          && Buffer.byteLength(content) <= 65536, "Invalid repair file.");
        const blob = await github.rest.git.createBlob({ ...repo, content: Buffer.from(content).toString("base64"), encoding: "base64" });
        tree.push({ path: file, mode: "100644", type: "blob", sha: blob.data.sha });
      }
      const created = await github.rest.git.createTree({ ...repo, base_tree: commit.tree.sha, tree });
      requireValue(created.data.sha === bundle.tree, "The published tree differs from the validated tree.");
      const createdCommit = await github.rest.git.createCommit({
        ...repo, message: "fix: resolve flake update compatibility failures", tree: created.data.sha, parents: [plan.sha],
      });
      verifyPr(await getPr(), plan.sha);
      publication.candidateCommit = createdCommit.data.sha;
      publication.status = "publication-uncertain";
      publication.reason = "The branch update has started. Its result is not confirmed.";
      saveReport(env.REPAIR_REPORT, report);
      await github.rest.git.updateRef({ ...repo, ref: "heads/automation/update-flake-inputs", sha: createdCommit.data.sha, force: false });
      newSha = createdCommit.data.sha;
      Object.assign(publication, { status: "published", commit: newSha, reason: "The exact validated tree was published." });
      saveReport(env.REPAIR_REPORT, report);
      await github.rest.repos.createCommitStatus({
        ...repo, sha: newSha, context: "update-flake / repair-validation", state: "success",
        target_url: report.runUrl,
        description: "All 8 repaired targets and required baseline builds passed. No uploads were run.",
      });
      publication.statusCreated = true;
      core.setOutput("repair-sha", newSha);
    }
    pr = await getPr();
    verifyPr(pr, newSha ?? plan.sha);
    publication.prUpdated = true;
    try {
      await github.rest.pulls.update({ ...repo, pull_number: plan.pr, body: updateBody(pr.body, renderReport(report, true)) });
    } catch (error) { publication.prUpdated = false; throw error; }
    const marker = `<!-- nixfiles-flake-repair:${context.runId}:${env.RUN_ATTEMPT} -->`;
    const comments = await github.paginate(github.rest.issues.listComments, { ...repo, issue_number: plan.pr, per_page: 100 });
    const previous = comments.find(comment => comment.user?.type === "Bot" && comment.body?.includes(marker));
    publication.commentUpdated = true;
    const body = `${marker}\n${renderReport(report, true)}`;
    try {
      if (previous) await github.rest.issues.updateComment({ ...repo, comment_id: previous.id, body });
      else await github.rest.issues.createComment({ ...repo, issue_number: plan.pr, body });
    } catch (error) { publication.commentUpdated = false; throw error; }
    await core.summary.addHeading("automated remediation report", 2)
      .addRaw(renderReport(report, true)).addLink("view workflow run", report.runUrl).write();
  } catch (error) {
    publication.error = String(error.message).slice(0, 2000);
    if (publication.status !== "published" && publication.status !== "publication-uncertain") {
      publication.status = "blocked";
      publication.reason = publication.error;
    }
    throw error;
  } finally {
    saveReport(env.REPAIR_REPORT, report);
  }
}

module.exports = publish;
module.exports.updateBody = updateBody;
module.exports.plain = plain;
module.exports.renderReport = renderReport;
