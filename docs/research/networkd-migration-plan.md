# systemd-networkd Migration Plan

## Recommendation

Migrate the active systems `bastion`, `voyager`, and `quasar` from
NetworkManager to systemd-networkd, one host at a time. Keep iwd as the Wi-Fi
association and credential manager, but make networkd the only owner of
addresses, DHCP, routes, metrics, DNS handoff, and online status.

The Lowy and Hickey lens debate reached these conclusions:

- Keep shared network-manager mechanics centralized.
- Keep physical topology and routing policy host-specific.
- Do not build a generic network-profile abstraction.
- Do not redesign DNS, Tailscale, containers, or firewall policy during this
  migration.
- Treat the migration as three independently gated changes, not one fleet-wide
  switch.
- Exclude archival `oldflake/hosts/nixiso`, which is not imported by the current
  flake.

The migration is worthwhile if the objective is declarative network ownership.
It is not worthwhile merely to replace one daemon with another.

## Current Topology

| Host | Physical interfaces | LAN identity | Special considerations |
| --- | --- | --- | --- |
| `bastion` | `enp39s0`, USB `eth0`, `wlan0` | `192.168.50.151` | Multiple uplinks, Noctalia, iwd, Docker, Tailscale |
| `voyager` | `wlan0` | Dynamic or unknown | Roaming laptop, Noctalia, suspend/resume, captive portals |
| `quasar` | `enp0s31f6` | `192.168.50.208` | CoreDNS, AdGuard, containers, LAN DNS anchor |

The existing `network.ip` values are service identities. They do not currently
configure addresses on an interface. Before writing networkd address settings,
determine whether `.151` and `.208` are router DHCP reservations or
host-assigned static addresses.

## Stay vs. Migrate

### Stay on NetworkManager

Benefits:

- Existing connections and credentials already work.
- Strong roaming, captive-portal, VPN, and desktop integration.
- No change to resolver, route metrics, or boot-online behavior.
- No remote-access risk during migration.
- Noctalia currently uses its preferred NetworkManager path.

Costs:

- Network configuration remains partly mutable and implicit.
- NetworkManager is unnecessary overhead on headless `quasar`.
- Physical routing policy is difficult to audit declaratively.
- NetworkManager is enabled both in the shared networking aspect and Noctalia.
- Boot readiness and multi-link routing remain dependent on mutable profiles.

### Migrate to networkd and iwd

Benefits:

- Addresses, routes, metrics, DHCP, and online requirements become declarative.
- Wi-Fi association is separated from layer-3 configuration.
- `quasar` gets a smaller, more appropriate networking stack.
- `bastion` gets exact control over link priority and failover.
- Noctalia's pinned upstream revision has a direct iwd backend.

Costs and risks:

- Existing Wi-Fi profiles may need conversion or recreation.
- Captive portals, enterprise Wi-Fi, and VPN workflows need explicit testing.
- Incorrect matching or routing can disconnect the machine.
- Resolver ownership can change accidentally.
- `systemd-networkd-wait-online` needs explicit per-link policy.
- Removing NetworkManager may temporarily reduce desktop integration.

Do not retain a permanent hybrid. Running two operational models is more
complex than either final state.

## Target Architecture

### Shared system policy

- Set `networking.networkmanager.enable = false`.
- Enable `systemd.network.enable`.
- Use `networking.useNetworkd = true` where NixOS-generated network
  configuration must use networkd.
- Stop disabling only `NetworkManager-wait-online`.
- Define intentional networkd wait-online behavior.

### Wi-Fi policy

- Enable iwd directly on `bastion` and `voyager`.
- Set iwd's `EnableNetworkConfiguration` to false.
- Let iwd associate and authenticate only.
- Let networkd obtain addresses and install routes.
- Validate Noctalia's direct-iwd integration before removing the NetworkManager
  applet.

### Host topology

- Declare native `systemd.network.networks` units in each host module.
- Match exact physical interfaces or stable hardware identities.
- Never use broad wildcard matching that could capture `tailscale0`, Docker or
  libvirt bridges, veth devices, or tunnel interfaces.
- Declare DHCP, static addressing, route metrics, DNS acceptance, IPv6
  behavior, and `RequiredForOnline` separately for each link.
- Do not introduce a generic network-profile schema or server/laptop mode
  switches.

### Resolver policy

- Preserve the current resolver mechanism initially.
- Do not introduce systemd-resolved as part of this migration.
- Resolve `/etc/resolv.conf` ownership before activation.
- Decide explicitly whether each DHCP link may supply host DNS.

## DNS Preservation

The existing service path must remain unchanged:

```text
LAN client
  -> CoreDNS on quasar:53
     -> authoritative *.sucha.foo records
     -> or DNS-over-TLS to 192.168.50.208:853
        using dns.quasar.sucha.foo as TLS server name
        -> AdGuard container
```

Keep these unchanged:

- CoreDNS TCP and UDP port `53`.
- AdGuard TCP and UDP port `853`.
- AdGuard container mappings and certificates.
- CoreDNS-generated records for `bastion.sucha.foo` and `quasar.sucha.foo`.
- Docker DNS setting `192.168.50.1`.
- Existing service-specific firewall declarations.
- CoreDNS and AdGuard monitoring endpoints.

DNS acceptance tests:

1. Resolve `bastion.sucha.foo` and `quasar.sucha.foo` over UDP and TCP.
2. Resolve several external domains over UDP and TCP.
3. Confirm CoreDNS can open TLS to `192.168.50.208:853`.
4. Verify the certificate using `dns.quasar.sucha.foo`.
5. Verify another LAN machine can query `quasar` on port 53.
6. Verify `quasar` can reach its own `.208:853` endpoint.
7. Verify containers still resolve through `192.168.50.1`.
8. Reject the migration if authoritative DNS works but recursive forwarding
   fails.

## Tailscale Preservation

Keep the existing Tailscale configuration unchanged:

- `--advertise-exit-node`
- `--ssh`
- `useRoutingFeatures = "both"`
- Loose reverse-path checking
- UDP port `41641`
- Tailscale-managed routes and policy rules

After each host migration:

1. Check `tailscale status`.
2. Ping peers through Tailscale.
3. Test Tailscale SSH.
4. Compare `ip rule` and all route tables before and after.
5. Select the host as an exit node from another device.
6. Verify public internet egress through the selected exit node.
7. Verify intended LAN reachability through that host.
8. Confirm networkd has not claimed `tailscale0`.

Also confirm whether advertising every host as an exit node is intentional.
That behavior predates and is independent of this migration.

## Host Rollout

### 1. Bastion canary

Migrate `bastion` first, from its local console. It is the best canary because
it exercises the most complex topology while remaining locally recoverable.

- Create separate exact-match units for `enp39s0`, USB `eth0`, and `wlan0`.
- Identify which interface currently owns `192.168.50.151`.
- Determine uplink preference and route metrics.
- Decide whether USB Ethernet is a normal uplink, fallback, or special-purpose
  link.
- Mark removable and fallback links as not required for online.
- Configure iwd as association-only.
- Test onboard Ethernet alone.
- Test Wi-Fi alone.
- Insert and remove USB Ethernet.
- Test simultaneous links and default-route selection.
- Test link failure and failover.
- Exercise Noctalia scan, connect, password prompt, disconnect, forget, and
  reconnect.
- Test Docker, normal SSH, Tailscale SSH, exit-node use, suspend/resume, reboot,
  and rollback.
- Accept `bastion` only after post-reboot checks pass and the previous
  NetworkManager generation still reconnects.

### 2. Voyager mobility gate

Migrate `voyager` second while physically present.

- Create one exact-match networkd unit for `wlan0`.
- Preserve observed DHCP, DNS, route, IPv4, and IPv6 behavior.
- Import or recreate all required Wi-Fi profiles in iwd before disabling
  NetworkManager.
- Test home Wi-Fi and at least one new network.
- Test credential persistence and roaming.
- Test captive-portal behavior if it is required.
- Test cold boot, suspend/resume, airplane-mode transitions, and loss and
  recovery of signal.
- Verify Noctalia's complete direct-iwd workflow.
- Verify Tailscale reconnects after every transition.
- Require two successful reboots before acceptance.

### 3. Quasar service gate

Migrate `quasar` last because it is the DNS and container anchor.

- Require console, serial, IPMI, or equivalent recovery access.
- Create one exact-match networkd unit for `enp0s31f6`.
- Preserve the proven acquisition method for `192.168.50.208`.
- Do not infer static addressing from
  `hardware.facter.detected.dhcp.enable = false`.
- Leave Docker, CoreDNS, AdGuard, firewall, and Tailscale service configuration
  unchanged.
- Verify `.208`, gateway, route tables, and resolver behavior.
- Verify Docker bridges and container health.
- Run the complete DNS and Tailscale gates.
- Verify all LAN services before and after reboot.

## Implementation Sequence

1. Record the current state:
   - Interfaces and hardware identities
   - Addresses and routes
   - Route metrics and policy rules
   - DHCP leases and client identifiers
   - IPv6 behavior
   - `/etc/resolv.conf` ownership
   - NetworkManager profiles
   - iwd state
   - Tailscale state
   - Firewall rules
2. Resolve the blocking questions below.
3. Add shared networkd and association-only iwd policy.
4. Add explicit host `.network` units.
5. Adapt Noctalia to direct iwd and prove it works while NetworkManager is
   unavailable.
6. Build without activating:

   ```bash
   nix flake check
   nix build .#nixosConfigurations.bastion.config.system.build.toplevel
   nix build .#nixosConfigurations.voyager.config.system.build.toplevel
   nix build .#nixosConfigurations.quasar.config.system.build.toplevel
   ```

7. Migrate `bastion`, then `voyager`, then `quasar`.
8. Remove `network-manager-applet` only after both workstation gates pass.
9. Retain rollback generations and profile backups through several reboots and
   at least one network interruption per host.

## Rollback

Before each host:

- Back up `/etc/NetworkManager/system-connections`.
- Back up `/var/lib/iwd`.
- Confirm the current generation boots and reconnects correctly.
- Confirm it is selectable in the bootloader.
- Ensure local or out-of-band access is available.

Activate temporarily first:

```bash
sudo nixos-rebuild test --flake .#<host>
```

Do not make the generation boot-default merely because SSH initially works.
Accept it only after temporary activation, cold reboot, complete post-reboot
tests, and a proven path back to the NetworkManager generation.

On any link, route, DNS, Tailscale, firewall, container, or Noctalia failure,
reboot into the previous generation and stop the rollout.

## Blocking Questions

Resolve these before implementation:

1. Are `.151` and `.208` DHCP reservations or host-assigned addresses?
2. What subnet prefix, gateway, DHCP server, client identifier, and IPv6 policy
   are currently used?
3. Which `bastion` interface owns `.151`?
4. What is the intended priority among `bastion`'s three uplinks?
5. What is USB `eth0` used for?
6. Which service owns `/etc/resolv.conf` on each host?
7. Should DHCP-provided DNS be accepted on each link?
8. Which links should satisfy `network-online.target`?
9. Which mounts, backups, containers, or services require online ordering?
10. Are all Wi-Fi credentials directly usable by iwd?
11. Are enterprise Wi-Fi, captive portals, NetworkManager VPNs, or custom
    routes in use?
12. Are the observed interface names stable?
13. Is exit-node advertisement intentional on all three hosts?
14. Is reliable recovery access available for `quasar`?
