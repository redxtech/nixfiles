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
      packageRoot = toString ../../packages;
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
          python3 ${./packages-to-readme.py} ${packageMetadataFile} "$repository_root/readme.md"
        '';
      };
    in
    {
      apps.packages-to-readme = {
        type = "app";
        program = lib.getExe packagesToReadme;
        meta.description = "Update the README package list from local flake packages";
      };
    };
}
