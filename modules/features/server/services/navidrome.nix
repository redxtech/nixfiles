{
  den.aspects.navidrome.nixos =
    { config, host, ... }:
    {
      monitoring.scrapeTargets.navidrome = 4533;
      network.services.music = 4533;

      services.navidrome = {
        enable = true;
        openFirewall = true;
        settings = {
          Address = "0.0.0.0";
          BaseURL = "https://music.${config.networking.fqdn}";
          DataFolder = "${host.settings.server.configRoot}/navidrome";
          MusicFolder = "${host.settings.server.mediaRoot}/music";

          EnableGravatar = true;
          EnableSharing = true;
          Jukebox.Enabled = true;
          LastFM2.Enabled = true;
          Prometheus.Enabled = true;
        };
      };

      systemd.services.navidrome.serviceConfig.EnvironmentFile = config.sops.secrets.navidrome_env.path;
      sops.secrets.navidrome_env.sopsFile = host.settings.server.legacySopsFile;
    };
}
