"""Fail-closed policy for bounded, evidence-backed compatibility repairs."""

import difflib
import hashlib
import json
import re
import subprocess
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
    r"sandbox|insecure|unfree|assert|check|test|patch|hash|fetch|update|portal|user|"
    r"crypto|openssl|gnutls|certificate|privilege|capability|oauth|jwt",
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

DEPENDENCY_LISTS = {
    "buildInputs",
    "nativeBuildInputs",
    "propagatedBuildInputs",
    "propagatedNativeBuildInputs",
    "checkInputs",
    "nativeCheckInputs",
    "runtimeInputs",
    "dependencies",
    "build-system",
    "depsBuildBuild",
    "depsBuildHost",
    "depsBuildTarget",
    "depsHostHost",
    "depsHostTarget",
    "depsTargetTarget",
}
MISSING_DEPENDENCY = re.compile(
    r"not found|no (?:package|module named)|cannot find|could not find|"
    r"could not locate|cannot locate|missing (?:dependency|package|library|module)",
    re.IGNORECASE,
)
PROTECTED_DEPENDENCY = re.compile(
    r"auth|secret|password|token|credential|permission|polkit|sudo|ssh|firewall|network|"
    r"wireguard|openvpn|strongswan|iptables|nftables|iproute|iputils|libpcap|tcpdump|nmap|"
    r"tailscale|traefik|attic|sops|boot|kernel|linux|hardware|disk|filesystem|storage|"
    r"database|postgres|mysql|sqlite|"
    r"migration|backup|recovery|systemd|security|sandbox|hardening|insecure|"
    r"crypto|openssl|gnutls|certificate|privilege|capability|oauth|jwt|"
    r"fetch|runCommand|callPackage|mkDerivation|builtins|override|hook|"
    r"make(?:Shell|Binary)?Wrapper|separateDebugInfo|setupDebugInfoDirs",
    re.IGNORECASE,
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


def package_path(path):
    return (
        isinstance(path, str)
        and bool(re.fullmatch(r"packages/[A-Za-z0-9_./-]+\.(?:nix|patch)", path))
        and str(PurePosixPath(path)) == path
        and ".." not in PurePosixPath(path).parts
        and not re.search(SENSITIVE.pattern.replace("|patch", ""), path, re.IGNORECASE)
    )


def dependency_change(original, offset, old, new, evidence, package):
    binding = re.compile(
        r"(?P<head>\s*(?P<key>[A-Za-z-]+)\s*=\s*\[)(?P<body>[^\[\]]*)(?P<tail>\]\s*;\s*)\Z"
    )
    before, after = binding.fullmatch(old), binding.fullmatch(new)
    require(
        before is not None
        and after is not None
        and before["key"] in DEPENDENCY_LISTS
        and before["head"] == after["head"]
        and before["tail"] == after["tail"],
        "Only an existing literal dependency list can change.",
    )
    require(
        code_mask(original)[offset : offset + len(old)] == old,
        "The dependency list is inside a string or comment.",
    )
    reference = rf"{IDENTIFIER}(?:\.{IDENTIFIER})*"
    items = []
    for match in (before, after):
        require(
            re.fullmatch(rf"\s*(?:{reference}(?:\s+{reference})*)?\s*", match["body"]),
            "Dependency lists must contain only attribute references.",
        )
        items.append(match["body"].split())
    existing, updated = items
    remaining = iter(existing)
    expected = next(remaining, None)
    additions = []
    for item in updated:
        if item == expected:
            expected = next(remaining, None)
        else:
            additions.append(item)
    require(
        expected is None
        and 0 < len(additions) <= 8
        and len(set(additions)) == len(additions)
        and not set(additions).intersection(existing),
        "A dependency repair must add one to eight entries without removal, replacement, reordering, or duplication.",
    )
    package_prefix = re.compile(rf"^\s*{re.escape(package)}>\s*", re.IGNORECASE)
    errors = [
        line[match.end() :]
        for line in evidence.splitlines()
        if (match := package_prefix.match(line))
        and MISSING_DEPENDENCY.search(line[match.end() :])
    ]
    for item in additions:
        require(
            item.startswith("pkgs.") and not PROTECTED_DEPENDENCY.search(item),
            "New dependencies must use unprotected pkgs attribute references.",
        )
        parts = item.split(".")
        if len(parts) > 2 and parts[-1] in {"dev", "lib", "bin", "out", "static"}:
            parts.pop()
        name = "[-_]".join(re.escape(part) for part in re.split("[-_]", parts[-1]))
        require(
            any(
                re.search(rf"(?<![\w-])(?:lib)?{name}(?![\w-])", line, re.IGNORECASE)
                for line in errors
            ),
            "Each new dependency must appear in a missing-dependency error.",
        )
    return original[:offset] + new + original[offset + len(old) :]


def check_patch_syntax(text):
    check = subprocess.run(
        ["git", "apply", "--numstat", "-"],
        input=text,
        text=True,
        capture_output=True,
        check=False,
    )
    require(check.returncode == 0, "The source patch is not a valid unified diff.")


def compatibility_change(snapshot, edit):
    path, old, new = edit["path"], edit["old"], edit["new"]
    require(package_path(path), "Only local package recipes and patches can change.")
    require(
        all(isinstance(value, str) and 0 < len(value) <= 8192 for value in (old, new)),
        "Invalid compatibility edit text.",
    )
    require(
        old != new
        and old.endswith("\n")
        and new.endswith("\n")
        and "\x00" not in old + new
        and "\r" not in old + new,
        "A compatibility edit must replace complete text lines.",
    )
    original = snapshot["files"][path]
    lines = original.splitlines(keepends=True)
    line = edit["line"]
    require(1 <= line <= len(lines), "The edit line is outside the source file.")
    offset = sum(len(value) for value in lines[: line - 1])
    require(
        original.startswith(old, offset) and original.count(old) == 1,
        "The compatibility edit does not match unique source text.",
    )
    changed = [
        value[2:]
        for value in difflib.ndiff(old.splitlines(), new.splitlines())
        if value.startswith(("+ ", "- "))
    ]
    require(len(changed) <= 80, "The compatibility edit changes too many lines.")
    if edit["kind"] == "dependency-addition":
        require(path.endswith(".nix"), "A dependency repair must change a Nix recipe.")
        return dependency_change(
            original, offset, old, new, edit["evidence"], PurePosixPath(path).parts[1]
        )
    protected = re.compile(
        r"auth|secret|password|token|credential|permission|polkit|sudo|ssh|firewall|"
        r"tailscale|traefik|attic|sops|boot|kernel|hardware|filesystem|database|"
        r"migration|backup|recovery|systemd|security|sandbox|hardening|insecure|"
        r"\b(?:version|rev|tag|src|sourceRoot|url|owner|repo|hash|sha\d*|outputHash|"
        r"[A-Za-z]*[Ii]nputs|dependencies|deps|patches|enable|disable[A-Za-z]*|"
        r"dont[A-Za-z]*|doCheck|doInstallCheck|check[A-Za-z]*|test[A-Za-z]*|"
        r"assert[A-Za-z]*|verify[A-Za-z]*|buildPhase|installPhase|phases|"
        r"preBuild|postBuild|preCheck|postCheck|preInstall|postInstall|"
        r"return|exit|throw|exec|curl|wget|eval|import|builtins|mkDerivation|runCommand)\b|"
        r"(?:check|test|assert|verify|disable|enable|skip|without)[A-Za-z0-9_]*|"
        r"crypto|openssl|gnutls|certificate|privilege|capability|oauth|jwt|"
        r"-fno-|-Wno-|FORTIFY_SOURCE|STACK_PROTECTOR|RELRO|NDEBUG|execstack",
        re.IGNORECASE,
    )
    require(
        not any(protected.search(value) for value in changed),
        "The compatibility edit affects a protected concern or build control.",
    )
    result = original[:offset] + new + original[offset + len(old) :]
    if edit["kind"] == "source-patch":
        require(
            path.endswith(".patch"),
            "A source-patch edit must change an existing patch.",
        )
        prefix = str(PurePosixPath(path).parent) + "/"
        require(
            any(
                name.startswith(prefix)
                and name.endswith(".nix")
                and f"./{PurePosixPath(path).name}" in source
                for name, source in snapshot["files"].items()
            ),
            "The patch is not referenced by its local package recipe.",
        )

        def headers(text):
            return [
                value
                for value in text.splitlines()
                if value.startswith(("diff --git ", "--- ", "+++ "))
            ]

        require(
            headers(original) == headers(result) and headers(original),
            "A patch cannot change its source file targets.",
        )
        require(
            not SENSITIVE.search("\n".join(headers(original))),
            "The patch source target affects a protected concern.",
        )
        require(
            original.count("\n@@ ") == result.count("\n@@ "),
            "A patch cannot add or remove hunks.",
        )
        require(
            not re.search(
                r"^(?:GIT binary patch|Binary files|.*file mode|(?:old|new) mode|(?:rename|copy) (?:from|to))",
                result,
                re.MULTILINE,
            ),
            "Only text patch hunks can change.",
        )
        pending = None
        seen_hunk = False
        for value in result.splitlines():
            if match := re.match(r"^@@ -\d+(?:,(\d+))? \+\d+(?:,(\d+))? @@", value):
                require(pending is None, "The previous patch hunk is incomplete.")
                pending = [int(match[1] or 1), int(match[2] or 1)]
                seen_hunk = True
                if pending == [0, 0]:
                    pending = None
            elif pending is not None:
                if value == "\\ No newline at end of file":
                    continue
                require(
                    bool(value) and value[0] in " +-", "Invalid patch hunk content."
                )
                pending[0] -= int(value[0] in " -")
                pending[1] -= int(value[0] in " +")
                require(min(pending) >= 0, "The patch hunk line counts do not match.")
                if pending == [0, 0]:
                    pending = None
            elif seen_hunk and value.startswith(("+", "-", " ")):
                require(
                    value.startswith(("--- ", "+++ ")) or value in ("--", "-- "),
                    "The patch has extra content outside its hunks.",
                )
        require(seen_hunk and pending is None, "The patch has an incomplete hunk.")
        check_patch_syntax(result)
    else:
        require(path.endswith(".nix"), "A package recipe edit must change a Nix file.")
        binding = re.match(
            r"\s*(NIX_CFLAGS_COMPILE|CFLAGS|CXXFLAGS|cmakeFlags|mesonFlags|configureFlags|makeFlags|postPatch)\s*=",
            old,
        )
        require(
            binding is not None,
            "Only complete compiler-flag or postPatch bindings can change.",
        )
        key = binding[1]
        require(
            re.match(rf"\s*{key}\s*=", code_mask(original)[offset:]),
            "The package binding is inside a string or comment.",
        )
        for text in (old, new):
            require(
                "${" not in text
                and re.fullmatch(
                    rf"\s*{key}\s*=\s*(?:\[\s*\])?\s*;\s*", code_mask(text)
                ),
                "The package binding must keep its name and use only literal strings.",
            )
    return result


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
        and failed_phase(record).get("infrastructure_failure") is not True
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
    compatibility_blocks = {}
    logs = {}
    for record in [*snapshot.get("historyFailures", []), *snapshot["failures"]]:
        logs[record["target"]] = (
            logs.get(record["target"], "") + "\n" + failed_phase(record)["log"]
        )
    for edit in edits:
        require(
            set(edit) == {"path", "line", "old", "new", "kind", "target", "evidence"},
            "Invalid edit fields.",
        )
        path, line = edit["path"], edit["line"]
        require(
            isinstance(path, str)
            and path in snapshot["files"]
            and (editable(path) or package_path(path)),
            "The edit path is not allowed.",
        )
        require(
            type(line) is int and (path, line) not in locations,
            "Invalid or duplicate edit location.",
        )
        locations.add((path, line))
        if edit["kind"] in (
            "package-compatibility",
            "source-patch",
            "dependency-addition",
        ):
            require(
                path not in changes,
                "Renames and compatibility blocks cannot share a file.",
            )
            evidence = edit["evidence"]
            require(
                isinstance(evidence, str)
                and 0 < len(evidence) <= 2000
                and edit["target"] in logs
                and evidence in logs[edit["target"]],
                "Evidence is not in a failed build log.",
            )
            require(
                MISSING_DEPENDENCY.search(evidence)
                if edit["kind"] == "dependency-addition"
                else re.search(
                    r"error:|fatal error|FAILED|failed with exit|does not apply|cannot (?:find|convert)|no matching",
                    evidence,
                    re.IGNORECASE,
                ),
                "The evidence does not identify a package compatibility failure.",
            )
            package = PurePosixPath(path).parts[1]
            if edit["kind"] == "dependency-addition":
                require(
                    package.lower() in evidence.lower(),
                    "The dependency error must identify the local package.",
                )
            require(
                package.lower() in logs[edit["target"]].lower(),
                "The failed log does not identify this local package.",
            )
            compatibility_change(snapshot, edit)
            original = snapshot["files"][path]
            offset = sum(
                len(value) for value in original.splitlines(keepends=True)[: line - 1]
            )
            end = offset + len(edit["old"])
            blocks = compatibility_blocks.setdefault(path, [])
            require(
                all(end <= start or offset >= stop for start, stop, _ in blocks),
                "Compatibility blocks cannot overlap in the original source.",
            )
            blocks.append((offset, end, edit["new"]))
            continue
        require(
            editable(path) and path not in compatibility_blocks,
            "The rename path is not allowed.",
        )
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
    for path, blocks in compatibility_blocks.items():
        result = snapshot["files"][path]
        for start, end, replacement in sorted(blocks, reverse=True):
            result = result[:start] + replacement + result[end:]
        if path.endswith(".patch"):
            check_patch_syntax(result)
        changes[path] = result
    require(len(changes) <= 3, "A repair can change at most three files.")
    require(
        all(len(value.encode()) <= 65536 for value in changes.values()),
        "A repair file exceeds the size limit.",
    )
    require(
        sum(len(value.encode()) for value in changes.values()) <= 196608,
        "Repair files exceed the size limit.",
    )
    if previous := snapshot.get("previous"):
        prior = apply_proposal({**snapshot, "previous": None}, previous["proposal"])
        require(changes != prior, "The revised proposal repeats the previous repair.")
    return changes
