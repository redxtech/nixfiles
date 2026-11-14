"""Record Nix failures separately from cache upload failures."""

import json
import os
import re
import subprocess
import sys
from contextlib import nullcontext
from pathlib import Path

from policy import INFRASTRUCTURE

LOG_LIMIT = 65536
RAW_LOG_LIMIT = 16 * 1024 * 1024


def run_phase(command, log_path=None):
    error = re.compile(
        rb"error:|fatal error|Hunk #\d+ FAILED|FAILED|builder failed", re.IGNORECASE
    )
    with open(log_path, "wb") if log_path else nullcontext() as stream:
        return collect_phase(command, stream, error)


def collect_phase(command, stream, error):
    tail, head, failure = b"", b"", b""
    found, total, infrastructure = False, 0, False
    with subprocess.Popen(
        command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT
    ) as process:
        while chunk := process.stdout.read1(8192):
            sys.stdout.buffer.write(chunk)
            sys.stdout.buffer.flush()
            if stream and total < RAW_LOG_LIMIT:
                stream.write(chunk[: RAW_LOG_LIMIT - total])
            infrastructure |= bool(
                INFRASTRUCTURE.search(
                    (tail[-4096:] + chunk).decode("utf-8", errors="replace")
                )
            )
            total += len(chunk)
            head = (head + chunk)[:4096]
            if not found and error.search(tail[-4096:] + chunk):
                found = True
                failure = tail[-4096:]
            if found:
                failure = (failure + chunk)[:45056]
            tail = (tail + chunk)[-LOG_LIMIT:]
        retained = (
            tail
            if total <= LOG_LIMIT
            else (
                head
                + b"\n[primary failure excerpt]\n"
                + failure
                + b"\n[final build output]\n"
                + tail[-14336:]
            )
        )
        return {
            "exit_code": process.wait(),
            "log": retained[:LOG_LIMIT].decode("utf-8", errors="replace"),
            "raw_log_truncated": total > RAW_LOG_LIMIT,
            "infrastructure_failure": infrastructure,
        }


def capture(target, result, directory):
    directory = Path(directory)
    directory.mkdir(parents=True, exist_ok=True)
    record = {
        "version": 1,
        "sha": os.environ["BUILD_REF"],
        "target": target,
        "phases": {},
        "complete": False,
    }
    path = directory / "diagnostic.json"

    def save():
        path.write_text(json.dumps(record))

    save()
    commands = {
        "evaluation": [
            "nix",
            "eval",
            f"{target}.drvPath",
            "--raw",
            "--show-trace",
            "--no-update-lock-file",
        ],
        "build": [
            "nix",
            "build",
            target,
            "--no-update-lock-file",
            "--out-link",
            result,
            "--print-build-logs",
        ],
    }
    status = 0
    for phase, command in commands.items():
        record["phases"][phase] = run_phase(command, directory / f"{phase}.log")
        status = record["phases"][phase]["exit_code"]
        save()
        if status:
            break
    record["complete"] = True
    save()
    return status if status >= 0 else 128 - status


if __name__ == "__main__":
    sys.exit(capture(*sys.argv[1:]))
