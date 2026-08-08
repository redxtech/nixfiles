{
  perSystem =
    {
      inputs',
      lib,
      pkgs,
      ...
    }:
    {
      packages.voxtype-full = inputs'.llm-agents.packages.voxtype.overrideAttrs (oldAttrs: {
        cargoBuildFeatures = [
          "cohere"
          "parakeet"
          "moonshine"
          "sensevoice"
          "paraformer"
          "dolphin"
          "osd-native"
          "osd-gtk4"
          "gpu-vulkan"
          "gpu-hipblas"
        ];
        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
          pkgs.shaderc
          pkgs.rocmPackages.clr
          pkgs.wrapGAppsHook4
        ];
        buildInputs = oldAttrs.buildInputs ++ [
          pkgs.onnxruntime
          pkgs.vulkan-headers
          pkgs.vulkan-loader
          pkgs.rocmPackages.clr
          pkgs.rocmPackages.hipblas
          pkgs.rocmPackages.rocblas
          pkgs.gtk4-layer-shell
          pkgs.libxkbcommon
        ];
        preBuild = (oldAttrs.preBuild or "") + ''
          export VULKAN_SDK="${pkgs.vulkan-loader}"
          export Vulkan_INCLUDE_DIR="${pkgs.vulkan-headers}/include"
          export Vulkan_LIBRARY="${lib.getLib pkgs.vulkan-loader}/lib/libvulkan.so"
          export HIP_PATH="${pkgs.rocmPackages.clr}"
          export ROCM_PATH="${pkgs.rocmPackages.clr}"
        '';
        postFixup = (oldAttrs.postFixup or "") + ''
          wrapProgram $out/bin/voxtype-osd-native \
            --prefix LD_LIBRARY_PATH : "${
              lib.makeLibraryPath [
                pkgs.vulkan-loader
                pkgs.wayland
              ]
            }"
        '';
        env = oldAttrs.env // {
          ORT_LIB_LOCATION = "${lib.getLib pkgs.onnxruntime}/lib";
          ORT_PREFER_DYNAMIC_LINK = "1";
        };
      });
    };
}
