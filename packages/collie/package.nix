{
  perSystem =
    { pkgs, ... }:
    let
      inherit (pkgs)
        bun
        coreutils
        curl
        fetchFromGitHub
        gawk
        git
        gnugrep
        gnused
        jq
        lib
        makeWrapper
        nix-update
        nodejs
        procps
        python3
        stdenvNoCC
        systemd
        tailscale
        ;
      version = "0.36.1";
      rev = "96c3bc3374ea49920ba1c62cfe3135277e16bf00";
      updateScript = pkgs.writeShellApplication {
        name = "update-collie";
        runtimeInputs = [
          curl
          jq
          nix-update
          python3
        ];
        text = ''
          packageFile=packages/collie/package.nix
          tag="$(curl --fail --silent --show-error \
            https://api.github.com/repos/AltanS/collie/releases/latest \
            | jq --exit-status --raw-output .tag_name)"
          version="''${tag#v}"
          commit="$(curl --fail --silent --show-error \
            "https://api.github.com/repos/AltanS/collie/commits/$tag")"
          rev="$(jq --exit-status --raw-output .sha <<<"$commit")"
          sourceDateEpoch="$(
            jq --exit-status --raw-output '.commit.committer.date | fromdateiso8601' \
              <<<"$commit"
          )"

          python3 - "$packageFile" "$version" "$rev" "$sourceDateEpoch" <<'PY'
          import pathlib
          import re
          import sys

          path = pathlib.Path(sys.argv[1])
          version, revision, source_date_epoch = sys.argv[2:]
          text = path.read_text()

          replacements = (
              (r'(?m)^(      version = ")[^"]+(";)$', version, "version"),
              (r'(?m)^(      rev = ")[^"]+(";)$', revision, "revision"),
              (
                  r'(?m)^(        SOURCE_DATE_EPOCH = ")[^"]+(";)$',
                  source_date_epoch,
                  "source date epoch",
              ),
          )
          for pattern, value, description in replacements:
              text, count = re.subn(pattern, rf'\g<1>{value}\g<2>', text, count=1)
              if count != 1:
                  raise SystemExit(
                      f"expected one {description} in {path}, replaced {count}"
                  )

          path.write_text(text)
          PY

          nix-update \
            --flake \
            --version=skip \
            --custom-dep nodeModules \
            "''${UPDATE_NIX_ATTR_PATH:-collie}"
        '';
      };
    in
    {
      packages.collie = stdenvNoCC.mkDerivation (finalAttrs: {
        pname = "collie";
        inherit version;

        src = fetchFromGitHub {
          owner = "AltanS";
          repo = "collie";
          inherit rev;
          hash = "sha256-CsTpMwHbzyDf/XEydN/67mQ31khQS2DKMs0Woy1TKR0=";
        };

        # bun has no nixpkgs dependency hook, so vendor both lockfile trees in one fixed-output derivation.
        nodeModules = stdenvNoCC.mkDerivation {
          pname = "collie-node-modules";
          inherit (finalAttrs) version src;

          impureEnvVars = lib.fetchers.proxyImpureEnvVars ++ [
            "GIT_PROXY_COMMAND"
            "SOCKS_SERVER"
          ];

          nativeBuildInputs = [ bun ];
          dontConfigure = true;

          buildPhase = ''
            runHook preBuild

            export BUN_INSTALL_CACHE_DIR=$(mktemp -d)
            bun install \
              --backend=copyfile \
              --frozen-lockfile \
              --ignore-scripts \
              --no-progress
            (
              cd web
              bun install \
                --backend=copyfile \
                --frozen-lockfile \
                --ignore-scripts \
                --no-progress
            )

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out/web
            cp -R node_modules $out/
            cp -R web/node_modules $out/web/

            runHook postInstall
          '';

          dontFixup = true;
          outputHash = "sha256-So9FBvdiGxqIH67wKaS8ObYgJEvDpfp61hexbJrpc9E=";
          outputHashAlgo = "sha256";
          outputHashMode = "recursive";
        };

        nativeBuildInputs = [
          bun
          makeWrapper
          nodejs
        ];
        # replace upstream's wall-clock and git probes with the pinned release revision and commit time.
        postPatch = ''
          substituteInPlace web/vite.config.ts \
            --replace-fail 'const buildSha = gitSha();' 'const buildSha = process.env.COLLIE_BUILD_SHA ?? gitSha();' \
            --replace-fail 'const buildTime = new Date().toISOString();' \
              'const buildTime = new Date(Number(process.env.SOURCE_DATE_EPOCH) * 1000).toISOString();'
        '';

        COLLIE_BUILD_SHA = builtins.substring 0 7 rev;
        SOURCE_DATE_EPOCH = "1788115964";

        configurePhase = ''
          runHook preConfigure

          cp -R ${finalAttrs.nodeModules}/. .
          patchShebangs node_modules web/node_modules

          runHook postConfigure
        '';

        buildPhase = ''
          runHook preBuild

          bun run typecheck
          (
            cd web
            bun run typecheck
            bun run build
          )

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall

          installRoot=$out/lib/collie
          mkdir -p $out/bin $out/libexec "$installRoot/scripts" "$installRoot/web"
          cp -R bridge node_modules "$installRoot/"
          cp package.json "$installRoot/"
          cp \
            scripts/collie-ctl.sh \
            scripts/push-keys.ts \
            scripts/push-test.ts \
            scripts/qr.ts \
            "$installRoot/scripts/"
          cp -R web/dist "$installRoot/web/"
          patchShebangs "$installRoot/scripts"

          makeWrapper ${lib.getExe bun} $out/bin/collie \
            --add-flags "run $installRoot/bridge/index.ts"
          makeWrapper "$installRoot/scripts/collie-ctl.sh" $out/libexec/collie-ctl-upstream \
            --prefix PATH : ${
              lib.makeBinPath [
                bun
                coreutils
                gawk
                git
                gnugrep
                gnused
                nodejs
                procps
                systemd
                tailscale
              ]
            }

          cat > $out/libexec/collie-ctl <<'EOF'
          #!@runtimeShell@
          case "''${1:-}" in
            start|stop|restart)
              exec @systemctl@ --user "$1" collie.service
              ;;
            status)
              exec @systemctl@ --user status --no-pager collie.service
              ;;
            logs)
              exec @journalctl@ --user -u collie.service --no-pager
              ;;
            version|push-test)
              exec @upstream@ "$@"
              ;;
            push-keys)
              echo "collie VAPID keys are managed by sops; update the configured secret instead" >&2
              exit 2
              ;;
            *)
              echo "usage: collie-ctl {start|stop|restart|status|logs|version|push-test}" >&2
              exit 2
              ;;
          esac
          EOF
          substituteInPlace $out/libexec/collie-ctl \
            --replace-fail @runtimeShell@ ${pkgs.runtimeShell} \
            --replace-fail @systemctl@ ${lib.getExe' systemd "systemctl"} \
            --replace-fail @journalctl@ ${lib.getExe' systemd "journalctl"} \
            --replace-fail @upstream@ $out/libexec/collie-ctl-upstream
          chmod +x $out/libexec/collie-ctl

          cat > "$installRoot/herdr-plugin.toml" <<EOF
          id = "herdr.collie"
          name = "Collie"
          version = "${finalAttrs.version}"
          min_herdr_version = "0.7.0"
          description = "Mobile web interface for Herdr"
          platforms = ["linux", "macos"]

          [[actions]]
          id = "start"
          title = "Start web bridge"
          contexts = ["workspace"]
          command = ["$out/libexec/collie-ctl", "start"]

          [[actions]]
          id = "stop"
          title = "Stop web bridge"
          contexts = ["workspace"]
          command = ["$out/libexec/collie-ctl", "stop"]

          [[actions]]
          id = "restart"
          title = "Restart web bridge"
          contexts = ["workspace"]
          command = ["$out/libexec/collie-ctl", "restart"]

          [[actions]]
          id = "status"
          title = "Bridge status"
          contexts = ["workspace"]
          command = ["$out/libexec/collie-ctl", "status"]

          [[actions]]
          id = "version"
          title = "Show version"
          contexts = ["workspace"]
          command = ["$out/libexec/collie-ctl", "version"]

          [[actions]]
          id = "push-test"
          title = "Send a test notification"
          contexts = ["workspace"]
          command = ["$out/libexec/collie-ctl", "push-test"]
          EOF

          runHook postInstall
        '';

        doInstallCheck = true;
        installCheckPhase = ''
          runHook preInstallCheck

          HERDR_PLUGIN_CONFIG_DIR=$(mktemp -d) $out/libexec/collie-ctl version \
            | grep -F ${finalAttrs.version}

          runHook postInstallCheck
        '';

        passthru.updateScript = lib.getExe updateScript;
        meta = {
          description = "Mobile web interface for monitoring and controlling Herdr sessions";
          homepage = "https://colliepwa.dev";
          changelog = "https://github.com/AltanS/collie/releases/tag/v${finalAttrs.version}";
          license = lib.licenses.mit;
          maintainers = [ lib.maintainers.redxtech ];
          mainProgram = "collie";
          platforms = [ "x86_64-linux" ];
        };
      });
    };
}
