{
  perSystem =
    { pkgs, lib, ... }:
    let
      inherit (pkgs)
        SDL2
        SDL2_image
        buildDotnetModule
        cmake
        copyDesktopItems
        dotnetCorePackages
        fetchFromGitHub
        fetchgit
        fetchurl
        gitMinimal
        libusb1
        libx11
        makeDesktopItem
        nasm
        ninja
        pkg-config
        stdenv
        ;

      sysdvrRev = "531e9c25c4e5a25954eeec677fe439fe812e9b19";

      cimgui-sdl2-cross = stdenv.mkDerivation {
        pname = "cimgui-sdl2-cross";
        version = "2";

        src = fetchgit {
          url = "https://github.com/exelix11/CimguiSDL2Cross.git";
          rev = "f878bb6680baf17d36a0f0cf21cdfeb091a77ec1";
          fetchSubmodules = true;
          hash = "sha256-76LnXoT82YpZ4NuAxC4HHL0WbNmIM+n2+bG5508EkMo=";
        };

        postPatch = ''
          cp patches/cimgui/imgui/backends/imgui_impl_sdl2.cpp \
            cimgui/imgui/backends/imgui_impl_sdl2.cpp
        '';

        nativeBuildInputs = [
          cmake
          ninja
          pkg-config
        ];
        buildInputs = [
          SDL2
          libx11
        ];

        cmakeDir = "../cimgui";
        cmakeFlags = [
          "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
          "-DIMGUI_STATIC=OFF"
        ];

        postInstall = ''
          mkdir -p $out/lib
          mv $out/cimgui.so $out/lib/cimgui.so
        '';

        strictDeps = true;
      };

      ffmpeg_5_1 = stdenv.mkDerivation (finalAttrs: {
        pname = "ffmpeg-sysdvr";
        version = "5.1.7";

        src = fetchurl {
          url = "https://ffmpeg.org/releases/ffmpeg-${finalAttrs.version}.tar.xz";
          hash = "sha256-J9h5ZcWwq4V6AJKuufVdl1vstxJtg67+Oa4kECSSGAs=";
        };

        postPatch = ''
          patchShebangs configure ffbuild
        '';

        nativeBuildInputs = [
          nasm
          pkg-config
        ];

        configureFlags = [
          "--enable-shared"
          "--disable-static"
          "--disable-doc"
          "--disable-programs"
          "--disable-autodetect"
        ];

        enableParallelBuilding = true;
        strictDeps = true;
      });
    in
    {
      packages.sysdvr = buildDotnetModule (finalAttrs: {
        pname = "sysdvr";
        version = "6.3";

        src = fetchFromGitHub {
          owner = "exelix11";
          repo = "SysDVR";
          tag = "v${finalAttrs.version}";
          hash = "sha256-EMcNsOhvfEA/dYB8DdsoH2tK2lNuBTlL68UrZAO4x/E=";
        };

        postPatch = ''
          substituteInPlace Client/Program.cs \
            --replace-fail \
              'public static readonly string BuildID = ThisAssembly.Git.Commit.ToString();' \
              'public static readonly string BuildID = "${sysdvrRev}";'
          substituteInPlace Client/Platform/Linux/sysdvr.rules \
            --replace-fail \
              'MODE="0666"' \
              'MODE="0660", TAG+="uaccess"'
        '';

        projectFile = "Client/Client.csproj";
        nugetDeps = ./deps.json;

        dotnet-sdk = dotnetCorePackages.sdk_9_0;
        dotnet-runtime = dotnetCorePackages.runtime_9_0;

        # Upstream's NativeAOT Linux build is coupled to its Flatpak SDK. Let
        # Nix provide the managed runtime and native dependencies instead.
        dotnetFlags = [
          "-p:PublishAot=false"
          "-p:SysDvrTarget=linux"
        ];

        executables = [ "SysDVR-Client" ];

        nativeBuildInputs = [
          copyDesktopItems
          gitMinimal
        ];

        runtimeDeps = [
          SDL2
          SDL2_image
          cimgui-sdl2-cross
          ffmpeg_5_1
          libusb1
        ];

        # Container detection makes SysDVR store settings below XDG_CONFIG_HOME
        # instead of beside its read-only executable. The upstream loader also
        # requests unversioned SDL and libusb names, which live in dev outputs.
        makeWrapperArgs = [
          "--set"
          "container"
          "nix"
          "--prefix"
          "LD_LIBRARY_PATH"
          ":"
          (lib.makeLibraryPath [
            SDL2.dev
            SDL2_image.dev
            libusb1.dev
          ])
        ];

        desktopItems = [
          (makeDesktopItem {
            name = "com.github.exelix11.sysdvr";
            desktopName = "SysDVR Client";
            comment = "Stream Nintendo Switch games over USB or the network";
            exec = "SysDVR-Client";
            icon = "com.github.exelix11.sysdvr";
            categories = [ "Game" ];
            keywords = [
              "Nintendo"
              "Switch"
            ];
          })
        ];

        postInstall = ''
          install -Dm644 Client/Platform/Linux/flatpak_icon.png \
            $out/share/icons/hicolor/256x256/apps/com.github.exelix11.sysdvr.png

          install -Dm644 Client/Platform/Linux/sysdvr.rules \
            $out/lib/udev/rules.d/99-sysdvr.rules
        '';

        doInstallCheck = true;
        installCheckPhase = ''
          runHook preInstallCheck

          $out/bin/SysDVR-Client --version | grep -F "SysDVR-Client ${finalAttrs.version}"
          $out/bin/SysDVR-Client --show-decoders | grep -F "h264"

          runHook postInstallCheck
        '';

        meta = {
          description = "Nintendo Switch game streaming client";
          homepage = "https://github.com/exelix11/SysDVR";
          changelog = "https://github.com/exelix11/SysDVR/releases/tag/v${finalAttrs.version}";
          license = lib.licenses.gpl2Only;
          maintainers = [ lib.maintainers.redxtech ];
          mainProgram = "SysDVR-Client";
          platforms = [ "x86_64-linux" ];
        };
      });
    };
}
