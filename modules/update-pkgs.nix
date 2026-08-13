{
  perSystem =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      nixUpdate = extraArgs: pkgs.nix-update-script { extraArgs = [ "--flake" ] ++ extraArgs; };
      packageUpdateScripts = {
        githubRelease = nixUpdate [ "--use-github-releases" ];
        githubReleaseWithRegex =
          regex:
          nixUpdate [
            "--use-github-releases"
            "--version-regex=${regex}"
          ];
        githubTagWithRegex = regex: nixUpdate [ "--version-regex=${regex}" ];
        githubTag = nixUpdate [ ];
        npm = nixUpdate [ ];
        unstable = nixUpdate [ "--version=branch" ];

        githubSource =
          {
            file,
            packageName,
            owner,
            repo,
            tagPrefix ? "v",
          }:
          pkgs.lib.getExe (
            pkgs.writeShellApplication {
              name = "update-${packageName}";
              runtimeInputs = with pkgs; [
                curl
                jq
                nix
                python3
              ];
              text = ''
                packageFile=${pkgs.lib.escapeShellArg file}

                tag="$(curl --fail --silent --show-error \
                  https://api.github.com/repos/${owner}/${repo}/releases/latest \
                  | jq --exit-status --raw-output .tag_name)"
                version="''${tag#${tagPrefix}}"
                sourceHash="$(
                  nix store prefetch-file --unpack --json \
                    "https://github.com/${owner}/${repo}/archive/refs/tags/$tag.tar.gz" \
                    | jq --exit-status --raw-output .hash
                )"

                python3 - "$packageFile" "$version" "$sourceHash" <<'PY'
                import pathlib
                import re
                import sys

                path = pathlib.Path(sys.argv[1])
                version, source_hash = sys.argv[2:]
                text = path.read_text()
                text, version_replacements = re.subn(
                    r'(?m)^(          version = ")[^"]+(";)$',
                    rf'\g<1>{version}\g<2>',
                    text,
                    count=1,
                )
                text, hash_replacements = re.subn(
                    r'(?m)^(            hash = ")[^"]+(";)$',
                    rf'\g<1>{source_hash}\g<2>',
                    text,
                    count=1,
                )
                if (version_replacements, hash_replacements) != (1, 1):
                    raise SystemExit(
                        f"unexpected replacements in {path}: "
                        f"version={version_replacements}, source hash={hash_replacements}"
                    )
                path.write_text(text)
                PY
              '';
            }
          );

        flakeInput =
          inputName:
          pkgs.lib.getExe (
            pkgs.writeShellApplication {
              name = "update-${inputName}-input";
              runtimeInputs = [ pkgs.nix ];
              text = ''
                nix flake update ${pkgs.lib.escapeShellArg inputName}
              '';
            }
          );

        local =
          packageName:
          pkgs.writeShellScript "update-${packageName}" ''
            echo "${packageName} is maintained in this repository and has no upstream source to update."
          '';
      };

      excludedPackages = [
        "bastion"
        "plex-pass-raw"
        "quasar"
        "vm"
        "voyager"
        "write-flake"
        "write-inputs"
        "write-lock"
      ];
      updatePackages = lib.filterAttrs (
        name: package: !(builtins.elem name excludedPackages) && package ? updateScript
      ) config.packages;
      updateCommands = lib.mapAttrsToList (
        name: package:
        let
          command = package.updateScript.command or package.updateScript;
        in
        ''
          run_update ${lib.escapeShellArg name} ${lib.escapeShellArgs (lib.toList command)}
        ''
      ) updatePackages;
    in
    {
      _module.args = { inherit packageUpdateScripts; };

      apps.update-pkgs = {
        type = "app";
        program = lib.getExe (
          pkgs.writeShellApplication {
            name = "update-pkgs";
            text = ''
              failures=()

              run_update() {
                local package="$1"
                shift

                printf '\n==> Updating %s\n' "$package"
                if UPDATE_NIX_ATTR_PATH="$package" "$@"; then
                  printf '==> %s succeeded\n' "$package"
                else
                  status=$?
                  failures+=("$package ($status)")
                  printf '==> %s failed with status %s\n' "$package" "$status" >&2
                fi
              }

              ${lib.concatStrings updateCommands}

              if ((''${#failures[@]} > 0)); then
                printf '\nPackage update failures:\n' >&2
                printf '  - %s\n' "''${failures[@]}" >&2
                exit 1
              fi

              printf '\nAll package update scripts succeeded.\n'
            '';
          }
        );
        meta.description = "Update all packages in the repository";
      };
    };
}
