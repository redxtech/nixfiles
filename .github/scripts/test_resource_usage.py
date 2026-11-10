import contextlib
import csv
import io
import math
import os
import subprocess
import sys
import tempfile
import threading
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path
from unittest import mock

import resource_usage as usage


class ResourceUsageTests(unittest.TestCase):
    def sample(self, elapsed: float = 0, cpu: float = math.nan) -> usage.Sample:
        return dict(
            zip(
                usage.FIELDS,
                [
                    elapsed,
                    cpu,
                    2 * usage.GIB,
                    8 * usage.GIB,
                    0,
                    10 * usage.GIB,
                    20 * usage.GIB,
                    10 * usage.GIB,
                ],
            )
        )

    def write_samples(self, output: Path, samples: list[usage.Sample]) -> None:
        with (output / "samples.csv").open("w", newline="") as stream:
            writer = csv.DictWriter(stream, fieldnames=usage.FIELDS)
            writer.writeheader()
            writer.writerows(samples)

    def test_cpu_does_not_count_guest_time_twice(self) -> None:
        with mock.patch.object(
            Path, "read_text", return_value="cpu 100 20 30 400 50 10 20 5 70 10\n"
        ):
            self.assertEqual(usage.read_cpu(), (635, 450))

    def test_cpu_delta_and_missing_interval(self) -> None:
        self.assertEqual(usage.cpu_percent((100, 70), (200, 100)), 70)
        self.assertTrue(math.isnan(usage.cpu_percent((100, 70), (100, 70))))
        self.assertEqual(usage.cpu_percent((100, 70), (200, 250)), 0)
        self.assertEqual(usage.cpu_percent((100, 70), (200, 0)), 100)

    def test_memory_uses_available_memory(self) -> None:
        memory = "MemTotal: 1000 kB\nMemFree: 100 kB\nMemAvailable: 600 kB\nSwapTotal: 200 kB\nSwapFree: 150 kB\n"
        with (
            mock.patch.object(Path, "read_text", return_value=memory),
            mock.patch.object(usage.time, "monotonic", return_value=105),
            mock.patch.object(usage, "free_bytes", return_value=123),
        ):
            sample = usage.snapshot(100, 20)
        self.assertEqual(sample["memory_used_bytes"], 400 * 1024)
        self.assertEqual(sample["swap_used_bytes"], 50 * 1024)
        self.assertEqual(sample["elapsed_seconds"], 5)
        self.assertEqual(sample["nix_free_bytes"], 123)

    def test_unavailable_disk_does_not_become_zero_free_space(self) -> None:
        with mock.patch.object(os, "statvfs", side_effect=FileNotFoundError):
            self.assertTrue(math.isnan(usage.free_bytes("/missing")))

    def test_disk_uses_available_blocks(self) -> None:
        stat = mock.Mock(f_bavail=10, f_frsize=4096)
        with mock.patch.object(os, "statvfs", return_value=stat):
            self.assertEqual(usage.free_bytes("/"), 40960)

    def test_record_preserves_success_and_failure_and_stops_sampler(self) -> None:
        for status in (0, 7):
            with (
                self.subTest(status=status),
                tempfile.TemporaryDirectory() as directory,
            ):
                output = Path(directory) / "resources"
                with mock.patch.object(usage, "SAMPLE_INTERVAL", 0.02):
                    result = usage.record(
                        [
                            sys.executable,
                            "-c",
                            f"import time; time.sleep(0.08); raise SystemExit({status})",
                        ],
                        output,
                    )
                self.assertEqual(result, status)
                samples = usage.read_samples(output / "samples.csv")
                self.assertGreaterEqual(len(samples), 2)
                self.assertGreater(samples[-1]["elapsed_seconds"], 0)
                self.assertFalse(
                    any(
                        thread.name == "resource-sampler"
                        for thread in threading.enumerate()
                    )
                )

    def test_signal_exit_status_is_preserved(self) -> None:
        with (
            tempfile.TemporaryDirectory() as directory,
            mock.patch.object(usage.subprocess, "call", return_value=-15),
        ):
            self.assertEqual(usage.record(["command"], Path(directory)), 143)

    def test_failed_sampling_does_not_skip_or_mask_command(self) -> None:
        with (
            tempfile.TemporaryDirectory() as directory,
            mock.patch.object(
                usage, "snapshot", side_effect=OSError("sample unavailable")
            ),
            mock.patch.object(usage.subprocess, "call", return_value=7) as command,
            contextlib.redirect_stderr(io.StringIO()) as errors,
        ):
            self.assertEqual(usage.record(["command"], Path(directory)), 7)
        command.assert_called_once_with(["command"])
        self.assertIn("::warning::", errors.getvalue())

    def test_failed_command_launch_stops_sampler(self) -> None:
        with (
            tempfile.TemporaryDirectory() as directory,
            mock.patch.object(usage.subprocess, "call", side_effect=FileNotFoundError),
            self.assertRaises(FileNotFoundError),
        ):
            usage.record(["missing"], Path(directory))
        self.assertFalse(
            any(thread.name == "resource-sampler" for thread in threading.enumerate())
        )

    def test_report_ignores_incomplete_final_csv_row(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            self.write_samples(output, [self.sample()])
            with (output / "samples.csv").open("a") as stream:
                stream.write("10,20\n")
            self.assertEqual(len(usage.read_samples(output / "samples.csv")), 1)

    def test_report_rejects_empty_samples(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            self.write_samples(output, [])
            with self.assertRaisesRegex(ValueError, "No complete"):
                usage.report(output)

    def test_report_creates_valid_svg_and_appends_summary(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            summary_path = output / "job-summary"
            summary_path.write_text("existing summary\n")
            samples = [self.sample(), self.sample(5, 50)]
            samples[-1]["root_free_bytes"] = usage.GIB
            samples[-1]["memory_used_bytes"] = 3 * usage.GIB
            self.write_samples(output, samples)
            with mock.patch.dict(
                os.environ, {"GITHUB_STEP_SUMMARY": str(summary_path)}
            ):
                usage.report(output)
            svg = ET.fromstring((output / "usage.svg").read_text())
            self.assertEqual(svg.tag, "{http://www.w3.org/2000/svg}svg")
            for polyline in svg.findall(".//{http://www.w3.org/2000/svg}polyline"):
                self.assertNotIn("nan", polyline.attrib["points"])
            text = summary_path.read_text()
            self.assertTrue(text.startswith("existing summary\n"))
            self.assertIn("| peak sampled RAM used | 3.0 GiB |", text)
            self.assertIn("| minimum sampled free space: / | 1.0 GiB |", text)
            self.assertIn("| mean sampled CPU busy | 50.0% |", text)
            self.assertTrue((output / "summary.md").is_file())

    def test_missing_disk_samples_are_reported_as_unavailable(self) -> None:
        samples = [self.sample()]
        for field in usage.FIELDS[-3:]:
            samples[0][field] = math.nan
        ET.fromstring(usage.render_svg(samples))
        self.assertIn(
            "| minimum sampled free space: / | not available |", usage.summary(samples)
        )

    def test_cli_records_failure_and_report_still_runs(self) -> None:
        script = str(Path(usage.__file__).resolve())
        with tempfile.TemporaryDirectory() as directory:
            command = [
                sys.executable,
                script,
                "record",
                "--output-dir",
                directory,
                "--",
                sys.executable,
                "-c",
                "raise SystemExit(9)",
            ]
            result = subprocess.run(
                command, check=False, capture_output=True, text=True
            )
            self.assertEqual(result.returncode, 9, result.stderr)
            result = subprocess.run(
                [sys.executable, script, "report", "--output-dir", directory],
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue((Path(directory) / "usage.svg").is_file())

    def test_cli_requires_command(self) -> None:
        result = subprocess.run(
            [sys.executable, usage.__file__, "record", "--output-dir", "/unused"],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 2)


if __name__ == "__main__":
    unittest.main()
