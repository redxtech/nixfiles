# Quasar Post-Migration Todos

These items are intentionally outside the configuration migration. They should not block a parity-preserving build unless a problem makes the migrated configuration invalid.

## Secrets

- [ ] Manually migrate the remaining keys from `oldflake/hosts/quasar/secrets.yaml` to `secrets/hosts/quasar/secrets.yaml`.
- [ ] Update service declarations to use the new Quasar SOPS file after the manual migration.
- [ ] Verify every migrated secret's owner, group, mode, generated path, and environment-file usage.
- [ ] Audit the apparently unused `data-pw`, `deluge-auth`, and `spotisub` keys before deciding whether to retain them.
- [ ] Remove the legacy SOPS fallback only after all references have moved.
- [ ] Remove `oldflake/hosts/quasar/secrets.yaml` and its `.sops.yaml` rule only after the fallback is gone.

## Oldflake Cleanup

- [ ] Remove the remaining Quasar oldflake directory after the legacy secret file is no longer needed.
- [ ] Remove `oldflake/modules/nixos/nas.nix` when no oldflake host imports it.
- [ ] Remove `lib/nas/` and stale exports after all new modules use the server vocabulary.
- [ ] Decide when the rest of `oldflake/` can be removed; keep this separate from the Quasar migration.

## Service Correctness Audit

- [ ] Check whether Jellyfin Vue should mount Jackett configuration and downloads; the old definition appears suspicious.
- [ ] Deduplicate the repeated Home Assistant PostgreSQL authentication lines and confirm the intended local/remote access policy.
- [ ] Confirm that the hard-coded UniFi controller address `192.168.1.1` is still correct for the current network.
- [ ] Resolve the `koinsight` container name versus `koinsights` port-name mismatch.
- [ ] Confirm whether the unused Startpage port represents a service that should exist or dead configuration that should be removed.
- [ ] Review hard-coded Quasar URLs and replace them with `config.networking.fqdn` where doing so preserves behavior.
- [ ] Review the Home Assistant SSH shell command and its private-key placement.
- [ ] Review qdirstat's read-only root filesystem mount and credential-file handling.
- [ ] Review Scrutiny's hard-coded disk list and broad `SYS_RAWIO`/`SYS_ADMIN` capabilities.
- [ ] Confirm whether the `yt` archive service name, mounts, and exposed behavior still match its actual purpose.
- [ ] Remove unused port constants and stale route names after the migrated runtime has been observed.

## Home Automation

- [ ] Determine whether the restored custom `python-unifi-ap` package is still necessary with the current Home Assistant integration stack.
- [ ] Audit the large Home Assistant `extraComponents` list for removed, renamed, or unused integrations.
- [ ] Audit custom Home Assistant components and Lovelace modules for compatibility with the current Home Assistant release.
- [ ] Confirm the Zigbee2MQTT serial device has a stable `/dev/serial/by-id` path and migrate away from `/dev/ttyUSB0` if possible.
- [ ] Decide whether PostgreSQL should remain private to Home Assistant or become shared infrastructure.
- [ ] Review whether InfluxDB remains necessary alongside Prometheus and Loki.

## Networking And Security

- [ ] Disable or protect Traefik's insecure API/dashboard if it does not need direct access.
- [ ] Review every `openFirewall` and explicit firewall rule; close ports used only through Traefik.
- [ ] Revisit the dedicated AdGuard certificate and default Traefik certificate arrangement after TLS parity is proven.
- [ ] Verify that `homeassistant-allow-iframe` has the narrowest acceptable content security policy.
- [ ] Review direct Docker socket mounts. Prefer the read-only socket proxy where service API coverage permits it.
- [ ] Confirm whether Cockpit, Portainer, and Traefik are intentionally enabled on Bastion and Voyager.
- [ ] Review the CoreDNS-to-AdGuard same-host dependency and document recovery DNS behavior when AdGuard is down.

## Containers

- [ ] Record deployed OCI image digests and decide whether to pin them.
- [ ] Define an explicit image-update policy instead of relying implicitly on floating tags and Watchtower.
- [ ] Add health checks and readiness handling where startup ordering alone is insufficient.
- [ ] Review the generated Docker-network systemd units after use and simplify them if NixOS gains suitable declarative network support.
- [ ] Audit host networking and privileged containers, especially Music Assistant and hardware-monitoring services.
- [ ] Verify NVIDIA device access and transcoding behavior for media containers.

## Observability And Tests

- [ ] Add evaluation tests for service-owned route registration, scrape-target registration, ports, and persistent paths.
- [ ] Add checks that every static Traefik route has one enabled backend and no duplicate router name.
- [ ] Add checks that every Alloy scrape target has an owning service.
- [ ] Add a NixOS VM test for the server substrate, generated Docker network units, and non-secret service wiring.
- [ ] Add a repeatable normalized Quasar configuration projection for future parity reviews.
- [ ] Add alerts for failed backups, failed containers, expiring certificates, and unavailable DNS.

## Data And Recovery

- [ ] Verify that every stateful service path is covered by an intentional backup or an explicit no-backup decision.
- [ ] Test restoring `/config/pods` and critical database state into an isolated environment.
- [ ] Document service startup dependencies on `/config` and `/pool` mounts.
- [ ] Document the manual deployment, rollback, and post-deployment verification procedure.
