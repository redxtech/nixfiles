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
- [ ] Decide when the rest of `oldflake/` can be removed; keep this separate from the Quasar migration.

## Networking And Security

- [ ] Review the CoreDNS-to-AdGuard same-host dependency and document recovery DNS behavior when AdGuard is down.

## Containers

- [ ] Add health checks and readiness handling where startup ordering alone is insufficient.
- [ ] Review the generated Docker-network systemd units after use and simplify them if NixOS gains suitable declarative network support.
- [ ] Audit host networking and privileged containers, especially Music Assistant and hardware-monitoring services.
- [ ] Verify NVIDIA device access and transcoding behavior for media containers.

## Observability And Tests

- [ ] Add alerts for failed backups, failed containers, expiring certificates, and unavailable DNS.
