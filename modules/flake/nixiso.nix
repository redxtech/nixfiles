{ self, lib, inputs, withSystem, ... }:

{
  perSystem = { config, self', inputs', pkgs, system, ... }: {
    # script to build nixiso
    apps = {
      build-nixiso = {
        type = "app";
        program = let
          buildISO = pkgs.writeShellApplication {
            name = "build-nixiso";
            runtimeInputs = with pkgs; [ nix ];
            text = ''
              nix build .#nixosConfigurations.nixiso.config.system.build.diskoImagesScript
            '';
          };
        in "${buildISO}/bin/build-nixiso";
      };

      write-nixiso = {
        type = "app";
        program = let
          writeISO = pkgs.writeShellApplication {
            name = "write-nixiso";
            runtimeInputs = with pkgs; [ disko ];
            text = ''
              set -eux

              main () {
              	if [ "$#" -ne 1 ]; then
              		echo "Usage: $0 <disk-id>"
              		exit 1
              	fi

              	exec disko-install --flake "${self}#nixiso" --disk main "$1"
              }

              main "$@"
            '';
          };
        in "${writeISO}/bin/write-nixiso";
      };
    };
  };
}

