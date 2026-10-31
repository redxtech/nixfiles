#!/usr/bin/env bash
set -euo pipefail

# upstream sandbox flags vary between releases, so the FHS wrapper owns launch behavior
desktop-file-edit --set-key=Exec --set-value='orca-ide %U' "$1"
desktop-file-validate "$1"
grep -Fxq 'Exec=orca-ide %U' "$1"
