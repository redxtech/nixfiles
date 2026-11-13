"""Record Nix failures separately from cache upload failures."""

import json
import os
import subprocess
import sys
from pathlib import Path

LOG_LIMIT = 65536


def run_phase(command):
    tail = b""
    with subprocess.Popen(
        command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT
    ) as process:
        while chunk := process.stdout.read1(8192):
            sys.stdout.buffer.write(chunk)
            sys.stdout.buffer.flush()
            tail = (tail + chunk)[-LOG_LIMIT:]
        return {
            "exit_code": process.wait(),
            "log": tail.decode("utf-8", errors="replace"),
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
        record["phases"][phase] = run_phase(command)
        status = record["phases"][phase]["exit_code"]
        save()
        if status:
            break
    record["complete"] = True
    save()
    return status if status >= 0 else 128 - status


if __name__ == "__main__":
    sys.exit(capture(*sys.argv[1:]))
