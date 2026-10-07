from __future__ import annotations

import heapq
from collections import defaultdict
from collections.abc import Callable
from dataclasses import dataclass
from typing import Any

from state import RunnerError, digest


def store_path(value: str) -> str:
    if not isinstance(value, str) or not value:
        raise RunnerError("The store path is missing.")
    path = value if value.startswith("/nix/store/") else "/nix/store/" + value
    if "/" in path.removeprefix("/nix/store/") or "^" in path or ".." in path:
        raise RunnerError("The store path is not supported.")
    return path


@dataclass(frozen=True)
class Node:
    outputs: dict[str, str | None]
    dependencies: tuple[tuple[str, str], ...]
    system: str


def normalize(document: dict[str, Any]) -> dict[str, Node]:
    records = document.get("derivations", document)
    graph: dict[str, Node] = {}
    for key, record in records.items():
        drv = store_path(key)
        if not drv.endswith(".drv"):
            raise RunnerError("The graph contains a non-derivation key.")
        outputs = {}
        for name, output in record["outputs"].items():
            if not isinstance(output, dict):
                raise RunnerError("The output definition is not supported.")
            if not output.get("path") and not (
                output.get("hash") and output.get("method")
            ):
                raise RunnerError("Unresolved output paths are not supported.")
            if not name or not name.replace("-", "").replace("_", "").isalnum():
                raise RunnerError("The output name is not supported.")
            outputs[name] = store_path(output["path"]) if output.get("path") else None
        dependencies = []
        inputs = record.get("inputDrvs", record.get("inputs", {}).get("drvs", {}))
        for dependency, requirement in inputs.items():
            if isinstance(requirement, dict):
                if requirement.get("dynamicOutputs"):
                    raise RunnerError("Dynamic outputs are not supported.")
                names = requirement["outputs"]
            else:
                names = requirement
            if not isinstance(names, list) or not names:
                raise RunnerError("The dependency output list is missing.")
            dependencies.extend((store_path(dependency), name) for name in names)
        graph[drv] = Node(outputs, tuple(dependencies), record["system"])
    return graph


def plan(
    graph: dict[str, Node],
    toplevel: str,
    valid: Callable[[list[str]], set[str]],
    batch_size: int = 32,
    resolve_output: Callable[[str, str], str] | None = None,
) -> dict[str, Any]:
    if batch_size < 1 or batch_size > 128:
        raise RunnerError("The batch size must be between 1 and 128.")
    toplevel = store_path(toplevel)
    if toplevel not in graph or "out" not in graph[toplevel].outputs:
        raise RunnerError("The toplevel derivation is missing.")
    required: dict[tuple[str, str], str] = {}
    boundaries: set[tuple[str, str]] = set()
    expanded: set[str] = {toplevel}
    frontier = list(graph[toplevel].dependencies)
    while frontier:
        layer = sorted(set(frontier) - set(required))
        if not layer:
            break
        paths = []
        for drv, output in layer:
            if drv == toplevel:
                raise RunnerError("The graph contains a toplevel dependency cycle.")
            if drv not in graph or output not in graph[drv].outputs:
                raise RunnerError("The graph is incomplete.")
            path = graph[drv].outputs[output]
            if path is None:
                if resolve_output is None:
                    raise RunnerError("The fixed-output path needs a Nix query.")
                path = store_path(resolve_output(drv, output))
            paths.append(path)
        available = valid(paths)
        frontier = []
        for (drv, output), path in zip(layer, paths):
            required[(drv, output)] = path
            if path in available:
                boundaries.add((drv, output))
                continue
            if drv not in expanded:
                expanded.add(drv)
                frontier.extend(graph[drv].dependencies)

    # dependency depth gives small prerequisites the first batches without one process per derivation
    depths: dict[str, int] = {}
    pending = set(expanded) - {toplevel}
    parents: dict[str, set[str]] = defaultdict(set)
    degrees: dict[str, int] = {}
    for drv in pending:
        dependencies = {dep for dep, _ in graph[drv].dependencies if dep in pending}
        degrees[drv] = len(dependencies)
        for dependency in dependencies:
            parents[dependency].add(drv)
    ready = [drv for drv in pending if not degrees[drv]]
    heapq.heapify(ready)
    while ready:
        drv = heapq.heappop(ready)
        depths[drv] = 1 + max(
            (depths.get(dep, 0) for dep, _ in graph[drv].dependencies), default=0
        )
        for parent in parents[drv]:
            degrees[parent] -= 1
            if not degrees[parent]:
                heapq.heappush(ready, parent)
    if len(depths) != len(pending):
        raise RunnerError("The graph contains a dependency cycle.")

    targets = sorted(
        set(required) - boundaries,
        key=lambda target: (depths.get(target[0], 0), target),
    )
    batches = []
    owners: dict[tuple[str, str], str] = {}
    for offset in range(0, len(targets), batch_size):
        group = targets[offset : offset + batch_size]
        batch_id = "batch-" + str(len(batches))
        for target in group:
            owners[target] = batch_id
        deps = sorted(
            {
                owners[(dep, name)]
                for drv, _ in group
                for dep, name in graph[drv].dependencies
                if (dep, name) in owners and owners[(dep, name)] != batch_id
            }
        )
        heavy = any(
            any(
                word in drv.lower()
                for word in (
                    "linux-",
                    "llvm",
                    "firefox",
                    "chromium",
                    "electron",
                    "rustc",
                )
            )
            for drv, _ in group
        )
        batches.append(
            {
                "id": batch_id,
                "deps": deps,
                "heavy": heavy,
                "targets": [
                    {"drv": drv, "output": output, "path": required[(drv, output)]}
                    for drv, output in group
                ],
            }
        )
    identity = {
        "toplevel": toplevel,
        "system": graph[toplevel].system,
        "output": graph[toplevel].outputs["out"],
    }
    return {
        "planId": digest({"identity": identity, "required": sorted(required.items())}),
        "identity": identity,
        "batches": batches,
        "boundaries": sorted(required[target] for target in boundaries),
        "requiredCount": len(required),
    }
