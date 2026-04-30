# aspect for the user "gabe"

{ den, ... }:

{
  den.aspects.gabe = {
    includes = [
      den._.primary-user
      (den._.user-shell "fish")

      den._.host-aspects
    ];

    nixos =
      { config, ... }:
      {
        users.mutableUsers = false;
        users.users.gabe = {
          description = "Gabe Dunn";
          isNormalUser = true;
          hashedPasswordFile = config.sops.secrets.gabe-pw.path;
          openssh.authorizedKeys.keys = [ (builtins.readFile ./ssh.pub) ];

          group = "gabe";
          extraGroups =
            let
              inherit (builtins) filter hasAttr;
              ifTheyExist = groups: filter (group: hasAttr group config.users.groups) groups;
            in
            (
              [
                "users"
                "video"
                "audio"
              ]
              ++ ifTheyExist [
                "data"
                "docker"
                "git"
                "hass"
                "input"
                "plugdev"
              ]
            );
        };

        users.groups.gabe = { };

        # TODO: add yubiauth mappings

        # base.yubiauth.mappings = [
        #   "gabe:MW9BvJEnapPkyE/UOpnT0skNdNyiTW/zk+ys+NJQIpcS9Ej7rHDL2AOdf8Wb/jYHAC9DSLRqf8SRbpjbW/I8wA==,6D2e7W3byi0MYF4CUfCjMwKTv0JVNL1izKYeKNOpzLlyEG4sKNfmqZWaS+9bfV6A+OlMbCT5g8v++D7nwnkNXg==,es256,+presence:MKn57WF5JlA9mSEhOEqJLJH2LMVS4wb44sR3Q8V/7D2H1xGuBuEMOc5pthRWC+5yN3URP1Ticw/o7bPWpOva0g==,CC6Ber5JNcC0I7IwXyL87reTvfZqZ+FVZQaiizTNS+g7QtxOeh6aDV/ztOoeRkS+wallUlKK9J3u4nco114fjw==,es256,+presence"
        # ];

        sops.secrets.gabe-pw.neededForUsers = true;
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          btop
          git

          alacritty
          fuzzel
          kitty
          kitty.terminfo
        ];
      };

    # user can provide NixOS configurations to any host it is included on
    provides.to-hosts.nixos =
      { pkgs, ... }:
      {
        # make gabe a trusted user in a couple of ways
        users.users.root.openssh.authorizedKeys.keys = [ (builtins.readFile ./ssh.pub) ];
        nix.settings.trusted-users = [ "gabe" ];
      };
  };
}
