{
  perSystem =
    {
      config,
      lib,
      options,
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
        githubTag = nixUpdate [ ];
        githubMatchingTag =
          {
            owner,
            packageName,
            repo,
            tagPrefix,
          }:
          pkgs.lib.getExe (
            pkgs.writeShellApplication {
              name = "update-${packageName}";
              runtimeInputs = [
                pkgs.curl
                pkgs.jq
                pkgs.nix-update
              ];
              text = ''
                version="$(
                  curl --fail --silent --show-error \
                    https://api.github.com/repos/${owner}/${repo}/git/matching-refs/tags/${tagPrefix} \
                    | jq --exit-status --raw-output --arg prefix 'refs/tags/${tagPrefix}' '
                      [
                        .[].ref
                        | select(startswith($prefix))
                        | ltrimstr($prefix)
                        | select(test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))
                        | { text: ., parts: (split(".") | map(tonumber)) }
                      ]
                      | sort_by(.parts)
                      | last
                      | .text
                    '
                )"

                nix-update --flake --version="$version"
              '';
            }
          );
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
                marker = "buildHomeAssistantComponent rec {"
                if text.count(marker) != 1:
                    raise SystemExit(
                        f"expected one component marker in {path}, found {text.count(marker)}"
                    )

                prefix, component = text.split(marker, maxsplit=1)
                component, version_replacements = re.subn(
                    r'(?m)^(\s+version = ")[^"]+(";.*)$',
                    rf'\g<1>{version}\g<2>',
                    component,
                    count=1,
                )
                component, hash_replacements = re.subn(
                    r'(?m)^(\s+hash = ")[^"]+(";.*)$',
                    rf'\g<1>{source_hash}\g<2>',
                    component,
                    count=1,
                )
                if (version_replacements, hash_replacements) != (1, 1):
                    raise SystemExit(
                        f"unexpected replacements in {path}: "
                        f"version={version_replacements}, source hash={hash_replacements}"
                    )
                path.write_text(prefix + marker + component)
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

      packageRoot = toString ../packages;
      packageDefinitions = lib.concatMap (
        definition:
        map (name: {
          inherit name;
          position = builtins.unsafeGetAttrPos name definition.value;
        }) (builtins.attrNames definition.value)
      ) options.packages.definitionsWithLocations;
      localPackageRecords =
        map
          (package: {
            inherit (package) name;
            source = "packages/${lib.removePrefix "${packageRoot}/" package.position.file}";
          })
          (
            lib.filter (
              package: package.position != null && lib.hasPrefix "${packageRoot}/" package.position.file
            ) packageDefinitions
          );
      localPackageNames = map (package: package.name) localPackageRecords;
      packageMetadata =
        assert lib.assertMsg (
          builtins.length localPackageNames == builtins.length (lib.unique localPackageNames)
        ) "package outputs must be defined by only one file under packages/";
        map (
          packageRecord:
          let
            package = config.packages.${packageRecord.name};
            version = lib.getVersion package;
          in
          packageRecord
          // {
            version = if version == "" then "unversioned" else version;
            description = package.meta.description or null;
            homepage = package.meta.homepage or null;
          }
        ) localPackageRecords;
      packageMetadataFile = pkgs.writeText "package-to-readme-metadata.json" (
        builtins.toJSON packageMetadata
      );
      packagesToReadmePython = pkgs.python3.withPackages (pythonPackages: [
        pythonPackages.markdown-it-py
      ]);
      packagesToReadme = pkgs.writeShellApplication {
        name = "packages-to-readme";
        runtimeInputs = [
          pkgs.git
          packagesToReadmePython
        ];
        text = ''
          repository_root="$(git rev-parse --show-toplevel)"
          python3 ${../scripts/packages-to-readme.py} ${packageMetadataFile} "$repository_root/readme.md"
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
      updatePackageNames = builtins.attrNames updatePackages;
      updateCases = lib.mapAttrsToList (
        name: package:
        let
          command = package.updateScript.command or package.updateScript;
        in
        ''
          ${lib.escapeShellArg name})
            run_update ${lib.escapeShellArg name} ${lib.escapeShellArgs (lib.toList command)}
            ;;
        ''
      ) updatePackages;
    in
    {
      _module.args = { inherit packageUpdateScripts; };

      apps.packages-to-readme = {
        type = "app";
        program = lib.getExe packagesToReadme;
        meta.description = "Update the README package list from local flake packages";
      };

      apps.update-pkgs = {
        type = "app";
        program = lib.getExe (
          pkgs.writeShellApplication {
            name = "update-pkgs";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.git
              pkgs.nix
            ];
            text = ''
              failures=()
              updates=()
              changelog_file="''${UPDATE_PKGS_CHANGELOG_FILE:-}"
              if [[ -n "$changelog_file" ]]; then
                : > "$changelog_file"
              fi

              snapshot_worktree() {
                local object_dir="$1"
                local index_file

                index_file="$(mktemp)"
                rm -f "$index_file"
                GIT_ALTERNATE_OBJECT_DIRECTORIES="$repository_objects" \
                  GIT_INDEX_FILE="$index_file" \
                  GIT_OBJECT_DIRECTORY="$object_dir" \
                  git read-tree HEAD
                GIT_ALTERNATE_OBJECT_DIRECTORIES="$repository_objects" \
                  GIT_INDEX_FILE="$index_file" \
                  GIT_OBJECT_DIRECTORY="$object_dir" \
                  git add -A -- .
                GIT_ALTERNATE_OBJECT_DIRECTORIES="$repository_objects" \
                  GIT_INDEX_FILE="$index_file" \
                  GIT_OBJECT_DIRECTORY="$object_dir" \
                  git write-tree
                rm -f "$index_file"
              }

              rollback_worktree() {
                local before="$1"
                local object_dir="$2"
                local after
                local index_file

                after="$(snapshot_worktree "$object_dir")"
                index_file="$(mktemp)"
                rm -f "$index_file"
                GIT_ALTERNATE_OBJECT_DIRECTORIES="$repository_objects" \
                  GIT_INDEX_FILE="$index_file" \
                  GIT_OBJECT_DIRECTORY="$object_dir" \
                  git read-tree "$after"
                GIT_ALTERNATE_OBJECT_DIRECTORIES="$repository_objects" \
                  GIT_INDEX_FILE="$index_file" \
                  GIT_OBJECT_DIRECTORY="$object_dir" \
                  git read-tree --reset -u "$before"
                rm -f "$index_file"
              }

              record_failure() {
                local package="$1"
                local phase="$2"
                local status="$3"

                failures+=("$package ($phase exited with status $status)")
                printf '==> %s %s failed with status %s; reverting its changes\n' \
                  "$package" "$phase" "$status" >&2
              }

              package_version() {
                local package="$1"

                nix eval --raw ".#$package" --apply '
                  package:
                  let
                    version = package.version or (builtins.parseDrvName package.name).version;
                  in
                  if version == "" then "unversioned" else version
                '
              }

              run_update() {
                local package="$1"
                local after
                local after_version
                local before
                local before_version
                local status
                local transaction_dir
                shift

                transaction_dir="$(mktemp -d)"
                mkdir -p "$transaction_dir/objects"
                before="$(snapshot_worktree "$transaction_dir/objects")"
                if before_version="$(package_version "$package")"; then
                  :
                else
                  status=$?
                  record_failure "$package" "pre-update version evaluation" "$status"
                  rm -rf "$transaction_dir"
                  return
                fi

                printf '\n==> Updating %s\n' "$package"
                if UPDATE_NIX_ATTR_PATH="$package" "$@"; then
                  after="$(snapshot_worktree "$transaction_dir/objects")"
                else
                  status=$?
                  record_failure "$package" "update" "$status"
                  rollback_worktree "$before" "$transaction_dir/objects"
                  rm -rf "$transaction_dir"
                  return
                fi

                if [[ "$before" == "$after" ]]; then
                  printf '==> %s is already up to date\n' "$package"
                  rm -rf "$transaction_dir"
                  return
                fi
                if after_version="$(package_version "$package")"; then
                  :
                else
                  status=$?
                  record_failure "$package" "post-update version evaluation" "$status"
                  rollback_worktree "$before" "$transaction_dir/objects"
                  rm -rf "$transaction_dir"
                  return
                fi

                printf '==> Building %s\n' "$package"
                if nix build --no-link ".#''${package}"; then
                  printf '==> %s update and build succeeded\n' "$package"
                  updates+=("$package: $before_version -> $after_version")
                else
                  status=$?
                  record_failure "$package" "build" "$status"
                  rollback_worktree "$before" "$transaction_dir/objects"
                fi
                rm -rf "$transaction_dir"
              }

              repository_root="$(git rev-parse --show-toplevel)"
              cd "$repository_root"
              git_common_dir="$(git rev-parse --git-common-dir)"
              if [[ "$git_common_dir" != /* ]]; then
                git_common_dir="$repository_root/$git_common_dir"
              fi
              repository_objects="$git_common_dir/objects"

              available_packages=( ${lib.escapeShellArgs updatePackageNames} )
              requested_packages=( "$@" )
              if ((''${#requested_packages[@]} == 0)); then
                requested_packages=( "''${available_packages[@]}" )
              else
                for package in "''${requested_packages[@]}"; do
                  package_exists=false
                  for available_package in "''${available_packages[@]}"; do
                    if [[ "$package" == "$available_package" ]]; then
                      package_exists=true
                      break
                    fi
                  done

                  if [[ "$package_exists" == false ]]; then
                    printf 'Unknown package: %s\n\nAvailable packages:\n' "$package" >&2
                    printf '  %s\n' "''${available_packages[@]}" >&2
                    exit 2
                  fi
                done
              fi

              for package in "''${requested_packages[@]}"; do
                case "$package" in
                  ${lib.concatStrings updateCases}
                esac
              done
              if ((''${#updates[@]} > 0)); then
                printf '\nPackage updates:\n'
                printf '  - %s\n' "''${updates[@]}"
                if [[ -n "$changelog_file" ]]; then
                  printf -- '- %s\n' "''${updates[@]}" > "$changelog_file"
                fi
              fi

              if ((''${#failures[@]} > 0)); then
                printf '\nPackage update failures:\n' >&2
                printf '  - %s\n' "''${failures[@]}" >&2
                exit 1
              fi

              printf '\nRequested package updates and builds succeeded.\n'
            '';
          }
        );
        meta.description = "Update all or selected packages in the repository";
      };
    };
}
