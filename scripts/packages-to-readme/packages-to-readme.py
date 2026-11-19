import json
import pathlib
import re
import sys
from dataclasses import dataclass
from typing import Any

from markdown_it import MarkdownIt


PACKAGE_HEADING = "## packages"
PACKAGE_CELL = re.compile(r"^\[`(?P<name>[^`]+)`\]\((?P<source>[^)]+)\)$")
MARKDOWN = MarkdownIt("commonmark").enable("table")


@dataclass(frozen=True)
class ExistingPackage:
    description: str
    upstream: str


@dataclass(frozen=True)
class Package:
    name: str
    source: str
    version: str
    description: str
    upstream: str
    group: str | None


def table_rows(section: str) -> list[list[str]]:
    rows: list[list[str]] = []
    current: list[str] | None = None
    in_table_body = False

    for token in MARKDOWN.parse(section):
        if token.type == "tbody_open":
            in_table_body = True
        elif token.type == "tbody_close":
            in_table_body = False
        elif token.type == "tr_open" and in_table_body:
            current = []
        elif token.type == "inline" and current is not None:
            current.append(token.content.strip())
        elif token.type == "tr_close" and current is not None:
            rows.append(current)
            current = None

    return rows


def package_section_bounds(text: str) -> tuple[int, int]:
    heading = re.search(rf"(?m)^{re.escape(PACKAGE_HEADING)}[ \t]*$", text)
    if heading is None:
        raise SystemExit(f"could not find {PACKAGE_HEADING!r} in the README")

    next_heading = re.search(r"(?m)^## .+$", text[heading.end() :])
    end = len(text) if next_heading is None else heading.end() + next_heading.start()
    return heading.start(), end


def existing_packages(section: str) -> dict[str, ExistingPackage]:
    packages: dict[str, ExistingPackage] = {}
    for cells in table_rows(section):
        if len(cells) < 3:
            continue

        package_cell = PACKAGE_CELL.fullmatch(cells[0])
        if package_cell is None:
            continue

        name = package_cell.group("name")
        if name in packages:
            raise SystemExit(f"README contains duplicate package row for {name!r}")

        packages[name] = ExistingPackage(
            description=cells[-2],
            upstream=cells[-1],
        )

    return packages


def markdown_cell(value: str) -> str:
    value = " ".join(value.split())
    return re.sub(r"(?<!\\)\|", r"\\|", value)


def prompt_for_description(name: str) -> str:
    while True:
        print(f"Description for {name}:", file=sys.stderr, end=" ", flush=True)
        answer = sys.stdin.readline()
        if answer == "":
            raise SystemExit(
                f"no description is available for {name!r}; rerun interactively to provide one"
            )

        answer = answer.strip()
        if answer:
            return markdown_cell(answer)

        print("Description cannot be empty.", file=sys.stderr)


def package_group(source: str) -> str | None:
    parts = pathlib.PurePosixPath(source).parts
    if not parts or parts[0] != "packages":
        raise SystemExit(f"package source is outside packages/: {source!r}")

    parent_parts = parts[1:-1]
    return parent_parts[0] if len(parent_parts) > 1 else None


def load_packages(
    metadata_path: pathlib.Path,
    existing: dict[str, ExistingPackage],
) -> list[Package]:
    metadata: Any = json.loads(metadata_path.read_text())
    if not isinstance(metadata, list):
        raise SystemExit("package metadata must be a JSON list")

    packages: list[Package] = []
    seen: set[str] = set()
    for item in metadata:
        if not isinstance(item, dict):
            raise SystemExit("each package metadata entry must be an object")

        name = item.get("name")
        source = item.get("source")
        version = item.get("version")
        if not all(isinstance(value, str) and value for value in (name, source, version)):
            raise SystemExit(f"invalid package metadata entry: {item!r}")
        if name in seen:
            raise SystemExit(f"duplicate package metadata for {name!r}")
        seen.add(name)

        current = existing.get(name)
        metadata_description = item.get("description")
        if isinstance(metadata_description, str) and metadata_description.strip():
            description = markdown_cell(metadata_description)
        elif current is not None and current.description.strip():
            description = markdown_cell(current.description)
        else:
            description = prompt_for_description(name)

        if current is not None:
            upstream = markdown_cell(current.upstream)
        else:
            homepage = item.get("homepage")
            upstream = (
                f"[source]({homepage.strip()})"
                if isinstance(homepage, str) and homepage.strip()
                else "—"
            )

        packages.append(
            Package(
                name=name,
                source=source,
                version=markdown_cell(version),
                description=description,
                upstream=upstream,
                group=package_group(source),
            )
        )

    return sorted(packages, key=lambda package: package.name)


def render_table(packages: list[Package]) -> list[str]:
    lines = [
        "| package | version | description | upstream |",
        "| --- | --- | --- | --- |",
    ]
    lines.extend(
        f"| [`{package.name}`]({package.source}) | `{package.version}` | "
        f"{package.description} | {package.upstream} |"
        for package in packages
    )
    return lines


def render_section(packages: list[Package]) -> str:
    ungrouped = [package for package in packages if package.group is None]
    groups = sorted({package.group for package in packages if package.group is not None})

    lines = [
        PACKAGE_HEADING,
        "",
        "<details>",
        f"<summary>show {len(packages)} packages</summary>",
        "",
        *render_table(ungrouped),
    ]

    for group in groups:
        grouped_packages = [package for package in packages if package.group == group]
        group_title = group.replace("-", " ").replace("_", " ")
        lines.extend(
            [
                "",
                "<details>",
                f"<summary>show {len(grouped_packages)} {group_title} packages</summary>",
                "",
                *render_table(grouped_packages),
                "",
                "</details>",
            ]
        )

    lines.extend(["", "</details>"])
    return "\n".join(lines)


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("usage: package-to-readme METADATA_JSON README")

    metadata_path = pathlib.Path(sys.argv[1])
    readme_path = pathlib.Path(sys.argv[2])
    text = readme_path.read_text()
    start, end = package_section_bounds(text)
    existing = existing_packages(text[start:end])
    packages = load_packages(metadata_path, existing)
    updated = text[:start] + render_section(packages) + "\n\n" + text[end:]

    if updated == text:
        print(f"{readme_path} is already up to date")
        return

    readme_path.write_text(updated)
    print(f"updated {readme_path}")


if __name__ == "__main__":
    main()
