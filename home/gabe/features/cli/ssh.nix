{ outputs, lib, ... }:
let hostnames = builtins.attrNames outputs.nixosConfigurations;
in {
  programs.ssh = let
    user = "gabe";
    identityFile = "~/.ssh/id_ed25519";
    remoteForwards = [{
      bind.address = "/%d/.gnupg-sockets/S.gpg-agent";
      host.address = "/%d/.gnupg-sockets/S.gpg-agent.extra";
    }];
  in {
    enable = true;

    # TODO: switch to tailscale IPs once it's set up
    matchBlocks = {
      "desktop" = {
        user = user;
        identityFile = identityFile;
        hostname = "10.0.0.59";
        forwardAgent = true;
        remoteForwards = remoteForwards;
      };
      "desktop-remote" = {
        user = user;
        identityFile = identityFile;
        hostname = "desktop.gabedunn.dev";
        forwardAgent = true;
        remoteForwards = remoteForwards;
      };
      "laptop" = {
        user = user;
        identityFile = identityFile;
        hostname = "10.0.0.161";
        port = 5022;
        forwardAgent = true;
        remoteForwards = remoteForwards;
      };
      "rock-hard" = {
        user = user;
        identityFile = identityFile;
        hostname = "10.0.0.191";
        forwardAgent = true;
        remoteForwards = remoteForwards;
      };
      "sb" = {
        user = "redxtech";
        identityFile = identityFile;
        hostname = "titan.usbx.me";
        forwardAgent = true;
        remoteForwards = remoteForwards;
      };
      "aur" = {
        user = "aur";
        identityFile = "~/.ssh/aur";
        # hostname = "titan.usbx.me";
      };
    };
  };
}
