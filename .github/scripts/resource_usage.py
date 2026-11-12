import argparse
import csv
import math
import os
import statistics
import subprocess
import sys
import tempfile
import threading
import time
from html import escape
from pathlib import Path

GIB = 1024**3
SAMPLE_INTERVAL = 5.0
FIELDS = (
    "elapsed_seconds",
    "cpu_percent",
    "memory_used_bytes",
    "memory_total_bytes",
    "swap_used_bytes",
    "root_free_bytes",
    "nix_free_bytes",
    "temp_free_bytes",
)
Sample = dict[str, float]
Series = tuple[str, str, str]


def read_cpu() -> tuple[int, int]:
    # guest time is already included in user and nice time
    counters = [
        int(value)
        for value in Path("/proc/stat").read_text().splitlines()[0].split()[1:9]
    ]
    return sum(counters), counters[3] + counters[4]


def cpu_percent(previous: tuple[int, int], current: tuple[int, int]) -> float:
    total = current[0] - previous[0]
    idle = current[1] - previous[1]
    if total <= 0:
        return math.nan
    return max(0.0, min(100.0, 100.0 * (total - idle) / total))


def free_bytes(path: str) -> float:
    try:
        stat = os.statvfs(path)
        return float(stat.f_bavail * stat.f_frsize)
    except OSError:
        return math.nan


def snapshot(start: float, cpu: float) -> Sample:
    memory = {}
    for line in Path("/proc/meminfo").read_text().splitlines():
        key, value, *_ = line.split()
        memory[key.rstrip(":")] = int(value) * 1024
    return {
        "elapsed_seconds": time.monotonic() - start,
        "cpu_percent": cpu,
        # use MemAvailable because it includes reclaimable memory
        # https://docs.kernel.org/filesystems/proc.html
        "memory_used_bytes": float(memory["MemTotal"] - memory["MemAvailable"]),
        "memory_total_bytes": float(memory["MemTotal"]),
        "swap_used_bytes": float(memory["SwapTotal"] - memory["SwapFree"]),
        "root_free_bytes": free_bytes("/"),
        "nix_free_bytes": free_bytes("/nix/store"),
        "temp_free_bytes": free_bytes(tempfile.gettempdir()),
    }


def collect(output: Path, stop: threading.Event) -> None:
    try:
        output.mkdir(parents=True, exist_ok=True)
        with (output / "samples.csv").open("w", newline="") as stream:
            writer = csv.DictWriter(stream, fieldnames=FIELDS)
            writer.writeheader()
            start = time.monotonic()
            previous = read_cpu()
            writer.writerow(snapshot(start, math.nan))
            stream.flush()
            while True:
                finished = stop.wait(SAMPLE_INTERVAL)
                current = read_cpu()
                writer.writerow(snapshot(start, cpu_percent(previous, current)))
                stream.flush()
                previous = current
                if finished:
                    break
    except (OSError, ValueError, KeyError) as error:
        print(f"::warning::Resource sampling stopped: {error}", file=sys.stderr)


def record(command: list[str], output: Path) -> int:
    stop = threading.Event()
    worker = threading.Thread(
        target=collect, args=(output, stop), name="resource-sampler", daemon=True
    )
    worker.start()
    try:
        returncode = subprocess.call(command)
        return 128 - returncode if returncode < 0 else returncode
    finally:
        stop.set()
        worker.join(timeout=10)
        if worker.is_alive():
            print("::warning::Resource sampling did not stop.", file=sys.stderr)


def read_samples(path: Path) -> list[Sample]:
    samples = []
    with path.open(newline="") as stream:
        for row in csv.DictReader(stream):
            try:
                sample = {key: float(row[key]) for key in FIELDS}
            except (TypeError, ValueError, KeyError):
                # a cancelled runner can leave an incomplete final row
                continue
            if math.isfinite(sample["elapsed_seconds"]):
                samples.append(sample)
    if not samples:
        raise ValueError("No complete resource samples are available.")
    return samples


def values(samples: list[Sample], key: str) -> list[float]:
    return [row[key] for row in samples if math.isfinite(row[key])]


def number(value: float) -> str:
    return f"{value:.1f}" if math.isfinite(value) else "not available"


def render_svg(samples: list[Sample]) -> str:
    duration = max(1.0, samples[-1]["elapsed_seconds"])
    time_scale = 60 if duration >= 120 else 1
    time_label = "elapsed minutes" if time_scale == 60 else "elapsed seconds"
    panels: list[tuple[str, float, float, list[Series]]] = [
        (
            "CPU busy (%)",
            1,
            100,
            [("cpu_percent", "all CPUs, normalized to 100%", "#2563eb")],
        ),
        (
            "memory (GiB)",
            GIB,
            max(
                values(samples, "memory_total_bytes")
                + values(samples, "swap_used_bytes")
            )
            / GIB,
            [
                ("memory_used_bytes", "RAM used (total minus available)", "#2563eb"),
                ("swap_used_bytes", "swap used", "#c2410c"),
            ],
        ),
        (
            "available disk space (GiB)",
            GIB,
            max(
                [
                    row[key] / GIB
                    for row in samples
                    for key in FIELDS[-3:]
                    if math.isfinite(row[key])
                ]
                or [1]
            ),
            [
                ("root_free_bytes", "/", "#2563eb"),
                ("nix_free_bytes", "/nix/store", "#15803d"),
                ("temp_free_bytes", "temporary filesystem", "#c2410c"),
            ],
        ),
    ]
    svg = [
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 790" role="img">',
        "<title>build resource usage</title>",
        '<rect width="1000" height="790" fill="white"/>',
        '<g font-family="sans-serif" font-size="12" fill="#111827">',
        '<text x="75" y="24" font-size="18">build resource usage</text>',
    ]
    for index, (title, scale, maximum, series) in enumerate(panels):
        top = 65 + index * 245
        maximum = max(maximum, 1)
        svg.append(f'<text x="75" y="{top - 16}" font-size="15">{escape(title)}</text>')
        for tick in range(5):
            y = top + 150 - tick * 37.5
            svg.append(f'<path d="M75 {y} H950" stroke="#e5e7eb"/>')
            svg.append(
                f'<text x="65" y="{y + 4}" text-anchor="end">{number(maximum * tick / 4)}</text>'
            )
            x = 75 + tick * 875 / 4
            svg.append(
                f'<text x="{x}" y="{top + 170}" text-anchor="middle">{number(duration * tick / 4 / time_scale)}</text>'
            )
        for key, label, color in series:
            points = " ".join(
                f"{75 + row['elapsed_seconds'] / duration * 875:.1f},"
                f"{top + 150 - row[key] / scale / maximum * 150:.1f}"
                for row in samples
                if math.isfinite(row[key])
            )
            svg.append(
                f'<polyline points="{points}" fill="none" stroke="{color}" stroke-width="2"/>'
            )
        svg.append(
            f'<text x="512" y="{top + 190}" text-anchor="middle">{time_label}</text>'
        )
        x = 75
        for _, label, color in series:
            svg.append(
                f'<text x="{x}" y="{top + 212}" fill="{color}">{escape(label)}</text>'
            )
            x += max(160, len(label) * 7 + 30)
    return "\n".join(svg + ["</g></svg>"])


def summary(samples: list[Sample]) -> str:
    cpu = values(samples, "cpu_percent")
    metrics = [
        ("sampled duration (minutes)", samples[-1]["elapsed_seconds"] / 60, ""),
        ("mean sampled CPU busy", statistics.fmean(cpu) if cpu else math.nan, "%"),
        (
            "peak sampled RAM used",
            max(values(samples, "memory_used_bytes")) / GIB,
            " GiB",
        ),
        ("RAM capacity", max(values(samples, "memory_total_bytes")) / GIB, " GiB"),
        (
            "peak sampled swap used",
            max(values(samples, "swap_used_bytes")) / GIB,
            " GiB",
        ),
    ]
    for key, label in [
        ("root_free_bytes", "/"),
        ("nix_free_bytes", "/nix/store"),
        ("temp_free_bytes", "temporary filesystem"),
    ]:
        available = values(samples, key)
        metrics.append(
            (
                f"minimum sampled free space: {label}",
                min(available) / GIB if available else math.nan,
                " GiB",
            )
        )
    lines = [
        "### build resource usage",
        "",
        "Nix command samples include evaluation and substitution. Attic and explicit Cachix uploads are outside this report.",
        "Background Cachix uploads can overlap the Nix command.",
        "",
        "RAM used is total minus available memory. CPU busy is normalized across all CPUs.",
        "",
        "| metric | value |",
        "| --- | ---: |",
    ]
    lines.extend(
        f"| {label} | {number(value)}{unit if math.isfinite(value) else ''} |"
        for label, value, unit in metrics
    )
    lines += [
        "",
        "The resource-usage artifact contains `usage.svg` and `samples.csv`.",
        "When phase timing is enabled, `timings.tsv` records the phase, elapsed seconds, and exit status.",
        "Sampling can miss brief peaks. The temporary filesystem follows the build step's `TMPDIR`.",
        "",
    ]
    return "\n".join(lines)


def report(output: Path) -> None:
    samples = read_samples(output / "samples.csv")
    (output / "usage.svg").write_text(render_svg(samples))
    text = summary(samples)
    (output / "summary.md").write_text(text)
    if path := os.environ.get("GITHUB_STEP_SUMMARY"):
        with Path(path).open("a") as stream:
            stream.write(text)


def main() -> int:
    parser = argparse.ArgumentParser()
    modes = parser.add_subparsers(dest="mode", required=True)
    recorder = modes.add_parser("record")
    recorder.add_argument("--output-dir", required=True, type=Path)
    recorder.add_argument("command", nargs=argparse.REMAINDER)
    reporter = modes.add_parser("report")
    reporter.add_argument("--output-dir", required=True, type=Path)
    args = parser.parse_args()
    if args.mode == "report":
        report(args.output_dir)
        return 0
    command = args.command
    if command and command[0] == "--":
        command = command[1:]
    if not command:
        parser.error("A command is required.")
    return record(command, args.output_dir)


if __name__ == "__main__":
    sys.exit(main())
