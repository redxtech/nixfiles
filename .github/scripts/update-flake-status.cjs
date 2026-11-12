const requiredJobs = ["update", "packages", "systems", "devshell"];

module.exports = async ({ github, context, core }, env = process.env) => {
  const needs = JSON.parse(env.NEEDS_JSON);
  const update = needs.update;
  const outputs = update.outputs;
  const hasPr = outputs["has-pr"] === "true";
  const sha = outputs["build-ref"];
  const targetUrl = `${context.serverUrl}/${context.repo.owner}/${context.repo.repo}/actions/runs/${context.runId}`;
  const status = {
    ...context.repo,
    sha,
    context: "update-flake / validation",
    target_url: targetUrl,
  };

  if (env.STATUS_PHASE === "pending") {
    if (!hasPr || !/^[0-9a-f]{40}$/.test(sha)) {
      throw new Error("An update PR head SHA is required.");
    }
    await github.rest.repos.createCommitStatus({
      ...status,
      state: "pending",
      description:
        "Package, system, devShell builds and cache uploads are pending.",
    });
    return;
  }

  const noUpdate =
    update.result === "success" &&
    outputs["has-pr"] === "false" &&
    outputs["should-build"] === "false";
  const required = hasPr ? [...requiredJobs, "status"] : requiredJobs;
  const success = required.every((job) => needs[job]?.result === "success");
  const rows = [
    [
      { data: "job", header: true },
      { data: "result", header: true },
    ],
    ...Object.entries(needs).map(([job, value]) => [job, value.result]),
  ];
  await core.summary
    .addHeading("update-flake validation", 2)
    .addRaw(
      noUpdate
        ? "No update PR exists. Builds and uploads were skipped.\n\n"
        : `Build commit: ${sha || "unavailable"}.\n\n`,
    )
    .addTable(rows)
    .addRaw(
      "\nEach build job includes cache uploads. Its summary contains separate Nix and upload timings.\n",
    )
    .addLink("view workflow run", targetUrl)
    .write();

  if (hasPr) {
    if (!/^[0-9a-f]{40}$/.test(sha)) {
      throw new Error("An update PR head SHA is required.");
    }
    await github.rest.repos.createCommitStatus({
      ...status,
      state: success ? "success" : "failure",
      description: success
        ? "All package, system, devShell builds and cache uploads passed."
        : "Validation failed, was cancelled, or did not complete.",
    });
  }
  if (!noUpdate && !success) {
    core.setFailed(
      "Required builds, cache uploads, or status reporting did not succeed.",
    );
  }
};
