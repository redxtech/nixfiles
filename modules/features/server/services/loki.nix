{
  den.aspects.loki.nixos =
    { config, ... }:
    let
      port = 3002;
      inherit (config.services.loki) dataDir;
    in
    {
      network.services.loki = port;

      services.loki = {
        enable = true;
        configuration = {
          auth_enabled = false;
          server.http_listen_port = port;

          common = {
            ring = {
              instance_addr = "0.0.0.0";
              kvstore.store = "inmemory";
            };
            replication_factor = 1;
            path_prefix = "${dataDir}/loki";
          };

          schema_config.configs = [
            {
              from = "2024-06-01";
              store = "tsdb";
              object_store = "filesystem";
              schema = "v13";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];

          storage_config.filesystem.directory = "${dataDir}/chunks";
        };

        extraFlags = [ "--server.http-listen-port=${toString port}" ];
      };
    };
}
