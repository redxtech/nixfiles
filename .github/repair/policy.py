"""Fail-closed policy for evidence-backed identifier renames."""

import hashlib
import json
import re
from pathlib import PurePosixPath

TARGETS = [
    *[
        f".#packages.x86_64-linux.{name}"
        for name in ("betterbird", "input-custom", "secretspec", "voxtype-full")
    ],
    *[
        f".#nixosConfigurations.{name}.config.system.build.toplevel"
        for name in ("bastion", "voyager", "quasar")
    ],
    ".#devShells.x86_64-linux.default",
]
SHA = re.compile(r"[0-9a-f]{40}\Z")
IDENTIFIER = r"[A-Za-z_][A-Za-z0-9_'\-]*"
ATTRIBUTE = re.compile(rf"{IDENTIFIER}(?:\.{IDENTIFIER})+\Z")
SENSITIVE = re.compile(
    r"auth|secret|password|token|credential|permission|polkit|sudo|ssh|firewall|network|"
    r"tailscale|traefik|cache|attic|sops|boot|kernel|hardware|disk|filesystem|storage|"
    r"database|postgres|mysql|sqlite|migration|backup|recovery|systemd|security|"
    r"sandbox|insecure|unfree|assert|check|test|patch|hash|fetch|update|portal|user",
    re.IGNORECASE,
)
INFRASTRUCTURE = re.compile(
    r"no space left on device|temporary failure in name resolution|could not resolve host|"
    r"connection timed out|connection reset|HTTP (?:error )?[45]\d\d|"
    r"unable to download|failed to download|out of memory|oom-kill|disk quota exceeded",
    re.IGNORECASE,
)
SUGGESTION = re.compile(
    r"renamed|has been moved|did you mean|use .{0,200} instead",
    re.IGNORECASE | re.DOTALL,
)


def require(condition, message):
    if not condition:
        raise ValueError(message)


def digest(value):
    return hashlib.sha256(
        json.dumps(value, sort_keys=True, separators=(",", ":")).encode()
    ).hexdigest()


def editable(path):
    parts = PurePosixPath(path).parts
    return (
        bool(parts)
        and not path.startswith("/")
        and ".." not in parts
        and str(PurePosixPath(path)) == path
        and path.endswith(".nix")
        and path.startswith(("modules/features/", "packages/"))
        and not SENSITIVE.search(path)
        and not path.startswith("modules/features/server/")
    )


def failed_phase(record):
    phases = record.get("phases", {})
    for name in ("evaluation", "build"):
        phase = phases.get(name)
        if phase and phase.get("exit_code") != 0:
            return phase
    return None


def prepare_records(records, sha):
    require(bool(SHA.fullmatch(sha)), "Invalid build SHA.")
    seen = set()
    failures = []
    for record in records:
        require(
            record.get("version") == 1 and record.get("sha") == sha,
            "Diagnostic identity does not match.",
        )
        target = record.get("target")
        require(
            target in TARGETS and target not in seen,
            "Invalid or duplicate diagnostic target.",
        )
        seen.add(target)
        require(record.get("complete") is True, "A build diagnostic is incomplete.")
        phases = record.get("phases", {})
        require(
            set(phases) in ({"evaluation"}, {"evaluation", "build"}),
            "Invalid diagnostic phases.",
        )
        for phase in phases.values():
            require(type(phase.get("exit_code")) is int, "Invalid exit status.")
            require(
                isinstance(phase.get("log"), str) and len(phase["log"]) <= 65536,
                "Invalid diagnostic log.",
            )
        if not failed_phase(record):
            require(
                set(phases) == {"evaluation", "build"},
                "A successful build phase is missing.",
            )
        if phase := failed_phase(record):
            failures.append(record)
    require(seen == set(TARGETS), "Diagnostics are missing for one or more targets.")
    eligible = bool(failures) and all(
        0 < failed_phase(record)["exit_code"] < 128
        and not INFRASTRUCTURE.search(failed_phase(record)["log"])
        for record in failures
    )
    return failures, eligible


def code_mask(text):
    # mask complete Nix strings, including nested interpolation and indented-string escapes
    def comment_end(index):
        if text[index] == "#":
            end = text.find("\n", index)
            return len(text) if end < 0 else end
        depth = 1
        index += 2
        while index < len(text) and depth:
            if text.startswith("/*", index):
                depth += 1
                index += 2
            elif text.startswith("*/", index):
                depth -= 1
                index += 2
            else:
                index += 1
        require(depth == 0, "The source has an incomplete comment.")
        return index

    def interpolation_end(index, depth):
        braces = 1
        while index < len(text):
            if text[index] == '"' or text.startswith("''", index):
                index = string_end(index, depth + 1)
            elif text[index] == "#" or text.startswith("/*", index):
                index = comment_end(index)
            else:
                if text[index] == "{":
                    braces += 1
                elif text[index] == "}":
                    braces -= 1
                    if not braces:
                        return index + 1
                index += 1
        raise ValueError("The source has an incomplete interpolation.")

    def string_end(index, depth=0):
        require(depth < 40, "The source string nesting exceeds the limit.")
        indented = text.startswith("''", index)
        delimiter = "''" if indented else '"'
        index += len(delimiter)
        while index < len(text):
            if indented and (
                text.startswith("'''", index) or text.startswith("''$", index)
            ):
                index += 3
            elif indented and text.startswith("''\\", index):
                index += 4
            elif not indented and text[index] == "\\":
                index += 2
            elif text.startswith("${", index):
                index = interpolation_end(index + 2, depth)
            elif text.startswith(delimiter, index):
                return index + len(delimiter)
            else:
                index += 1
        raise ValueError("The source has an incomplete string.")

    masked = list(text)
    index = 0
    while index < len(text):
        if text[index] == '"' or text.startswith("''", index):
            end = string_end(index)
        elif text[index] == "#" or text.startswith("/*", index):
            end = comment_end(index)
        else:
            index += 1
            continue
        masked[index:end] = ["\n" if char == "\n" else " " for char in text[index:end]]
        index = end
    return "".join(masked)


def apply_proposal(snapshot, proposal):
    require(
        set(proposal) == {"summary", "cause", "disposition", "edits"},
        "Invalid proposal fields.",
    )
    for field, limit in (("summary", 2000), ("cause", 6000)):
        require(
            isinstance(proposal[field], str) and 0 < len(proposal[field]) <= limit,
            "Invalid diagnosis text.",
        )
    require(
        proposal["disposition"] in ("repair", "report"), "Invalid repair disposition."
    )
    edits = proposal["edits"]
    require(isinstance(edits, list) and len(edits) <= 12, "Too many repair edits.")
    if proposal["disposition"] == "report":
        require(not edits, "A report cannot contain automatic edits.")
        return {}
    require(bool(edits), "A repair must contain edits.")
    changes = {}
    locations = set()
    logs = {
        record["target"]: failed_phase(record)["log"] for record in snapshot["failures"]
    }
    for edit in edits:
        require(
            set(edit) == {"path", "line", "old", "new", "kind", "target", "evidence"},
            "Invalid edit fields.",
        )
        path, line = edit["path"], edit["line"]
        require(
            isinstance(path, str) and editable(path) and path in snapshot["files"],
            "The edit path is not allowed.",
        )
        require(
            type(line) is int and (path, line) not in locations,
            "Invalid or duplicate edit location.",
        )
        locations.add((path, line))
        old, new = edit["old"], edit["new"]
        require(
            isinstance(old, str) and isinstance(new, str), "Invalid attribute name."
        )
        require(
            ATTRIBUTE.fullmatch(old) and ATTRIBUTE.fullmatch(new) and old != new,
            "Only dotted identifier renames are allowed.",
        )
        require(
            not SENSITIVE.search(old + " " + new),
            "The rename affects a protected concern.",
        )
        root = {"package-rename": "pkgs", "library-rename": "lib"}.get(edit["kind"])
        if edit["kind"] == "option-rename":
            require(
                old.rsplit(".", 1)[0] == new.rsplit(".", 1)[0]
                and old.startswith(("programs.", "xdg.")),
                "The option root is not allowed.",
            )
            require(
                old.split(".")[-1] != "enable" and new.split(".")[-1] != "enable",
                "Feature activation cannot change.",
            )
        else:
            require(
                root and old.startswith(root + ".") and new.startswith(root + "."),
                "Invalid rename category.",
            )
        evidence = edit["evidence"]
        require(
            isinstance(evidence, str) and 0 < len(evidence) <= 2000,
            "Invalid evidence excerpt.",
        )
        require(
            edit["target"] in logs and evidence in logs[edit["target"]],
            "Evidence is not in a failed build log.",
        )
        require(
            SUGGESTION.search(evidence),
            "Evidence must contain a rename or replacement suggestion.",
        )
        require(
            all(
                re.search(
                    rf"(?<![\w-]){re.escape(name.split('.')[-1])}(?![\w-])", evidence
                )
                for name in (old, new)
            ),
            "Evidence must name both identifiers.",
        )
        original = snapshot["files"][path]
        lines = changes.get(path, original).splitlines(keepends=True)
        require(1 <= line <= len(lines), "The edit line is outside the source file.")
        require(
            not SENSITIVE.search(lines[line - 1]),
            "The source line affects a protected concern.",
        )
        token = re.compile(rf"(?<![\w.'-]){re.escape(old)}(?![\w.'-])")
        masked = code_mask(original).splitlines()
        require(
            len(token.findall(masked[line - 1])) == 1,
            "The identifier must occur once outside strings and comments.",
        )
        if edit["kind"] == "option-rename":
            require(
                re.match(rf"\s*{re.escape(old)}\s*=", masked[line - 1]),
                "Only a complete option assignment can change.",
            )
        lines[line - 1], count = token.subn(new, lines[line - 1])
        require(count == 1, "The identifier is not unique on the source line.")
        changes[path] = "".join(lines)
    require(len(changes) <= 3, "A repair can change at most three files.")
    require(
        sum(len(value.encode()) for value in changes.values()) <= 196608,
        "Repair files exceed the size limit.",
    )
    return changes
