#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

for command in 'AppRun --no-sandbox %U' 'AppRun %U'; do
  cat > "$workdir/orca-ide.desktop" <<EOF
[Desktop Entry]
Name=Orca
Exec=$command
Terminal=false
Type=Application
Icon=orca-ide
StartupWMClass=orca
MimeType=text/markdown;x-scheme-handler/orca;
Categories=Utility;
EOF
  grep -v '^Exec=' "$workdir/orca-ide.desktop" > "$workdir/unchanged"
  bash "$script_dir/patch-desktop.sh" "$workdir/orca-ide.desktop"
  grep -Fx 'Exec=orca-ide %U' "$workdir/orca-ide.desktop"
  # desktop-file-edit also adds its own version metadata
  grep -Ev '^(Exec|X-Desktop-File-Install-Version)=' "$workdir/orca-ide.desktop" > "$workdir/actual"
  diff -u "$workdir/unchanged" "$workdir/actual"
done

# validation must still reject an invalid entry instead of concealing upstream drift
sed -i 's/Type=Application/Type=Invalid/' "$workdir/orca-ide.desktop"
if bash "$script_dir/patch-desktop.sh" "$workdir/orca-ide.desktop"; then
  echo 'Invalid desktop entry was accepted' >&2
  exit 1
fi
printf 'Desktop Exec regression checks passed\n'
