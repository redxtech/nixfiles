# DNS architecture investigation

## Executive conclusion

The current CoreDNS → AdGuard Home chain is effective for **static local service discovery plus DNS filtering**, but it does not meet the dynamic-registration requirement. It also puts the services in the wrong order for client-aware filtering: CoreDNS proxies every non-local query, so AdGuard Home does not see the original LAN client.

Given the clarified constraints:

- the router must remain the DHCP server;
- the design must work with both ASUSWRT and UniFi networks;
- tailnet clients should receive Tailscale addresses for `*.sucha.foo`;
- non-tailnet remote clients should receive normal public/Cloudflare answers;
- remote ad blocking should work through native encrypted DNS;
- reliability and clear ownership matter more than having one process;

I do **not** recommend forcing the design into one daemon.

The best target is:

1. **AdGuard Home is the client-facing filtering resolver.** It serves LAN DNS and the public DoH/DoT endpoint.
2. **A private authoritative DNS component owns `sucha.foo` views and dynamic records.** CoreDNS can remain temporarily, but a server with standard RFC 2136 updates, such as BIND 9 or Technitium, is a better long-term authority.
3. **Managed hosts register their own LAN addresses**, because the DHCP server cannot send updates and router-specific lease scraping is not portable.
4. **Tailscale split DNS sends only `sucha.foo` to the tailnet view.** All other remote queries can continue through the native public AdGuard DoH/DoT profile.
5. **The AdGuard administration UI remains private.** Only the encrypted DNS endpoint should be public.

This still uses two DNS roles, but each role has one clear owner. It is simpler than making AdGuard Home, CoreDNS, router lease APIs, and public ingress share mutable DNS policy.

## Direct answers

### Should one of the current services be dropped?

Not as a first step.

- **Keep AdGuard Home.** Replacing its filtering UI, client policies, encrypted DNS ClientIDs, and logs with CoreDNS plugins or BIND RPZ would add custom operational work.
- **Do not keep CoreDNS unchanged.** Its generated zone files are the source of the rebuild requirement, and its built-in `etcd` backend is explicitly not a general-purpose zone store. CoreDNS documents it as an older SkyDNS service-discovery backend with only a subset of record types. <https://coredns.io/plugins/etcd/>
- **Either narrow or replace CoreDNS.** In the short term, place it behind AdGuard and serve only local zones. In the long term, replace it with an authority that accepts authenticated RFC 2136 updates, or accept a bespoke AdGuard API reconciliation process.

If process count is the overriding goal, an AdGuard-only design is possible with generated, client-scoped `$dnsrewrite` rules. It is not the most reliable design because AdGuard Home is not a full authoritative or RFC 2136 server, and dynamic writers must safely reconcile one shared filtering configuration.

### Public URL or Tailscale when away from home?

Treat the administration UI and the DNS endpoint differently.

- **Administration UI:** use Tailscale, or Cloudflare Access if browser-only public access is required. Do not expose the unauthenticated management surface as part of the DNS route.
- **DNS endpoint:** a public hostname is appropriate because native Android Private DNS and Apple/browser DoH clients need a publicly reachable TLS endpoint. AdGuard Home supports ClientIDs for DoH, DoT, and DoQ, including URL and wildcard-hostname forms. <https://adguard-dns.io/kb/adguard-home/clients/>
- **Tailnet service names:** use Tailscale restricted/split DNS for `sucha.foo`. Tailscale sends only that suffix to the selected nameserver. <https://tailscale.com/docs/reference/dns-in-tailscale>

The public resolver must use an allowlist of ClientIDs, rate limiting, strict TLS/SNI checks, and no public plain-DNS recursion. AdGuard recommends allowlist mode for public instances with known encrypted-DNS clients. <https://adguard-dns.io/kb/adguard-home/running-securely/>

## Current state in the repository

### CoreDNS

`modules/features/server/services/coredns.nix`:

- evaluates every NixOS host with a non-null `network.ip`;
- generates one static zone per host;
- returns the host address for both the zone apex and every wildcard below it;
- listens on TCP/UDP port 53;
- forwards all unmatched queries over DoT to `dns.${fqdn}` on the server host.

The effective shape is:

```dns
quasar.sucha.foo.    A 192.168.50.208
*.quasar.sucha.foo.  A 192.168.50.208
```

The addresses originate in host settings such as `modules/hosts/quasar/quasar.nix`, so an address change requires evaluation, deployment, and service reload.

### AdGuard Home

`modules/features/server/services/adguard.nix`:

- runs `adguard/adguardhome:latest` in an OCI container;
- stores configuration and runtime data under the server config volume;
- maps plain DNS to host port `1053`;
- maps encrypted DNS ports including 853 and 1443;
- obtains a certificate containing `dns.${fqdn}` and wildcard DNS names;
- routes both `adguard.${fqdn}` and `dns.${fqdn}` through the same Traefik-labelled container service.

The persisted `AdGuardHome.yaml`, router NAT rules, and Tailscale DNS settings are outside the repository. The Nix configuration therefore does not fully declare the effective DNS behavior.

### Runtime observations

During this investigation:

- `dig @192.168.50.1 quasar` returned `192.168.50.208`;
- `dig @192.168.50.1 quasar.sucha.foo` returned `192.168.50.208`;
- the same queries through the currently used AdGuard server at `192.168.50.46` returned the same answer;
- Tailscale reported `quasar` at `100.124.66.105` and `voyager` at `100.107.238.120`.

These tests do **not** prove that ASUSWRT itself provides portable DHCP-name DNS. The router currently forwards to the AdGuard instance, and that instance already contains the relevant rewrites. The runtime resolver address (`192.168.50.46`) also differs from the AdGuard deployment visible in this branch, which is a configuration-drift signal.

## Why dynamic registration is the hard constraint

Dynamic DNS normally gets its lifecycle from the DHCP authority:

1. a lease is created or renewed;
2. the DHCP server adds or refreshes the DNS record;
3. the DHCP server removes the record when the lease expires or is released.

AdGuard Home can do this when it is the DHCP server, and it registers lease hostnames under `local_domain_name`. It limits those lease-derived A answers to locally served networks. <https://github.com/AdguardTeam/AdGuardHome/wiki/DHCP> <https://github.com/AdguardTeam/AdGuardHome/wiki/Configuration>

That path is unavailable because router DHCP must remain in place. There is no router-independent protocol by which an arbitrary DHCP server automatically publishes its leases to another DNS server. One compromise is therefore unavoidable:

| Registration source | Advantages | Costs |
|---|---|---|
| Router lease API or lease file | Tracks all DHCP clients and expiry | ASUSWRT and UniFi need separate adapters, credentials, and tests |
| Per-host update agent | Router-independent; ideal for Nix-managed hosts | Does not automatically cover unmanaged devices; abrupt disconnects need stale-record cleanup |
| AdGuard API reconciliation | Can support an AdGuard-only deployment | Bespoke shared-state writer; not standard DDNS |
| RFC 2136 to an authority | Standard, authenticated, well-supported | Requires an authoritative DNS component and a cleanup policy |
| Move DHCP to the DNS server | Best lease lifecycle | Explicitly ruled out for these networks |

For the three Nix-managed hosts, a per-host agent using RFC 2136 is the most portable choice. Use a short TTL and a periodic refresh. Add a server-side stale-record cleanup mechanism or retain DHCP reservations, because DNS TTL controls caching, not authoritative-record expiry.

## Recommended request paths

### 1. LAN client without Tailscale DNS

```text
LAN client
  -> router-advertised AdGuard Home :53
     -> filtering and client policy
     -> LAN client-specific upstream for sucha.foo
        -> private authoritative LAN view
     -> normal upstream for every other domain
```

AdGuard Home supports per-client upstream configuration. A client can be identified by CIDR, such as `192.168.50.0/24`. <https://adguard-dns.io/kb/adguard-home/clients/>

### 2. Tailnet client

```text
query for *.sucha.foo
  -> Tailscale restricted nameserver
     -> authoritative tailnet view
        -> Tailscale IP

query for every other domain
  -> native public AdGuard DoH/DoT profile
     -> filtering
     -> public upstream
```

Tailscale restricted nameservers apply only to a configured suffix. Do not enable a Tailscale global DNS override if the intended global path is the operating system's native encrypted-DNS profile. Enabling Override DNS servers makes tailnet clients ignore local global resolvers. <https://tailscale.com/docs/reference/dns-in-tailscale>

A client that is both on the LAN and accepting Tailscale split DNS will normally use the tailnet answer for `sucha.foo`. This matches the clarified preference that tailnet membership should select Tailscale addresses.

### 3. Remote client outside the tailnet

```text
remote client
  -> https://dns.example/dns-query/<client-id>
     or <client-id>.dns.example over DoT
  -> AdGuard filtering
  -> public upstream
  -> normal public/Cloudflare answer for *.sucha.foo
```

Do not configure a global internal rewrite for `sucha.foo`. Public ClientID clients should use the default upstream path.

## Local and tailnet zone design

Use explicit host records plus wildcard CNAMEs:

```dns
; LAN view, dynamically updated
quasar.sucha.foo.    300 IN A     192.168.50.208
*.quasar.sucha.foo.  300 IN CNAME quasar.sucha.foo.

; Tailnet view, stable or API-generated
quasar.sucha.foo.    300 IN A     100.124.66.105
*.quasar.sucha.foo.  300 IN CNAME quasar.sucha.foo.
```

This is better than repeating the address in both the apex and wildcard record. An address change modifies one host record, and all service names follow the CNAME.

The public authoritative Cloudflare zone remains unchanged and continues to point public service names at the Cloudflare Tunnel or other public ingress.

## Service options

### Option A — AdGuard Home before a narrowed CoreDNS

**Use as the lowest-risk migration step.**

- Move CoreDNS off public/LAN port 53 to a private high port.
- Remove its default forward back to AdGuard to prevent a loop.
- Put AdGuard Home on the client-facing LAN port.
- Give the LAN client group a `sucha.foo` conditional upstream to CoreDNS.
- Let public ClientID clients use public upstreams.
- Add a separate tailnet-only CoreDNS listener or server block for Tailscale answers.

CoreDNS supports CIDR-based split DNS through its `view` plugin when it sees the client source address. <https://coredns.io/plugins/view/>

**Limitation:** this does not solve standard DDNS. CoreDNS would still need generated files, an external registration store, or custom update automation.

### Option B — AdGuard Home plus BIND 9 authoritative DNS

**Recommended long-term architecture.**

- AdGuard Home owns filtering, encrypted transports, ClientIDs, and public access control.
- BIND owns authoritative LAN and tailnet views.
- Nix-managed hosts use TSIG-protected RFC 2136 updates for their LAN A records.
- Wildcard service records are static CNAMEs.
- The BIND query/update listeners are private and firewall-restricted.

BIND supports dynamic updates and view-specific DNS configuration. This is a mature standards-based boundary rather than an AdGuard configuration API convention. <https://bind9.readthedocs.io/>

**Limitation:** two daemons remain, and abrupt host disappearance needs an expiry or cleanup policy because an RFC 2136 record does not disappear merely because its TTL elapsed.

### Option C — AdGuard Home only

**Viable when one process is worth bespoke automation.**

AdGuard filtering rules can combine client scoping and DNS rewrites. The official syntax supports CIDR or persistent-client names with `$client`, and `$dnsrewrite` can return A, AAAA, CNAME, PTR, and other records. <https://adguard-dns.io/kb/general/dns-filtering-syntax/>

Example shape:

```text
||quasar.sucha.foo^$client=192.168.50.0/24,dnsrewrite=192.168.50.208
||quasar.sucha.foo^$client='tailnet',dnsrewrite=100.124.66.105
```

Unmatched public clients use normal upstream answers.

**Limitations:**

- AdGuard Home does not expose a full authoritative-zone or RFC 2136 model.
- A registrar must edit/reconcile shared custom rules safely.
- UI edits and generated rules can conflict.
- Stale-record cleanup is custom.
- DNSSEC and authoritative behavior are less explicit than with a real authority.

This can be reasonable for only three hosts, but it is not the clearest reliability-first design.

### Option D — Technitium DNS Server only

**Strongest one-service candidate.**

Technitium supports recursive and authoritative DNS, block lists, RFC 2136 dynamic updates, encrypted DNS, and split-horizon DNS applications. <https://github.com/TechnitiumSoftware/DnsServer>

It could replace both current services and keep router DHCP unchanged while hosts send RFC 2136 updates.

**Limitations:**

- It is a larger stateful platform and migration.
- Split horizon and advanced blocking depend on DNS Apps and their configuration.
- Public roaming-client identification and allowlisting are less directly documented than AdGuard Home ClientIDs.
- Nix would need to reconcile or back up Technitium's state and app configuration.

Run it on alternate ports as a prototype before selecting it.

### Option E — Router lease synchronization

Build one adapter for ASUSWRT and another for UniFi. Each adapter reads active leases and generates local records.

**Advantages:** all DHCP clients get lifecycle-aware records without changing DHCP.

**Limitations:** this is explicitly platform-specific, depends on router APIs or SSH access, and must be maintained across firmware/controller updates. It should be an optional source adapter, not the core DNS architecture.

## Public encrypted-DNS design

### Separate names and routes

Use separate exposure policies even if the same AdGuard process handles both:

- `adguard.<domain>`: administration UI, reachable only through Tailscale or Cloudflare Access;
- `dns.<domain>`: encrypted DNS protocol endpoint;
- `*.dns.<domain>`: ClientID hostnames for DoT/DoQ and optional hostname-based DoH.

The existing certificate already includes DNS wildcard names suitable for this pattern.

### Protocol choices

- **DoH on TCP 443:** best compatibility with restrictive networks and Apple/browser profiles.
- **DoT on TCP 853:** required for Android's built-in Private DNS hostname setting.
- **DoQ:** useful for AdGuard applications, but not necessary for the base design.

A Cloudflare Tunnel can be useful for the HTTP DoH path and hiding the home origin. It does not replace the direct public listener needed for ordinary DoT. The current repository routes the DNS hostname to the AdGuard web service port, so `/dns-query` routing must be tested rather than assumed.

### Required controls

1. Populate `allowed_clients` with LAN CIDRs and named encrypted-DNS ClientIDs.
2. Do not allow public UDP/TCP port 53 recursion.
3. Keep query rate limiting enabled.
4. Enable strict SNI validation.
5. If Traefik or Cloudflare proxies DoH, configure AdGuard's exact `trusted_proxies` and verify the real client address.
6. Route only the DoH path publicly; do not route the admin UI on the same unrestricted hostname.
7. Monitor certificate expiry, rejected clients, and query spikes.

AdGuard Home accepts CIDRs, IP addresses, and ClientIDs in `allowed_clients`, and it only trusts forwarded client-address headers from configured trusted proxies. <https://github.com/AdguardTeam/AdGuardHome/wiki/Configuration>

## Repository improvements independent of the final design

1. **Reverse the current chain.** AdGuard should see the client before forwarding local-zone queries.
2. **Stop publishing CoreDNS as a general resolver** once AdGuard is client-facing.
3. **Pin the AdGuard image** instead of using `latest`.
4. **Choose one configuration owner.** Either generate `AdGuardHome.yaml`, reconcile it through the API, or document it as intentional mutable state with tested backups.
5. **Declare Tailscale DNS policy** alongside the host configuration or document the required admin-console settings.
6. **Restrict firewall rules by interface.** LAN plain DNS, tailnet authoritative DNS, public DoH, and public DoT have different trust scopes.
7. **Use explicit CNAME wildcards** so dynamic host A records do not duplicate service addresses.
8. **Add stale-record monitoring.** Alert when a local A record does not match the registering host or has not refreshed within the expected interval.
9. **Add a second filtered resolver only if needed.** Multiple global resolvers can bypass policy if they differ, and operating systems do not guarantee ordered fallback. Tailscale documents this resolver-selection caveat. <https://tailscale.com/docs/reference/dns-in-tailscale>
10. **Document emergency DNS.** The current CoreDNS and AdGuard services share a host, so two processes do not create host-level redundancy.

## Migration plan

### Phase 1 — Make the existing system observable and reproducible

1. Export and back up the active `AdGuardHome.yaml` and work data.
2. Record router DHCP/DNS settings, public NAT rules, Cloudflare routes, and Tailscale DNS settings.
3. Reconcile why the active AdGuard address is `192.168.50.46` while this branch describes the quasar deployment.
4. Pin the AdGuard image.
5. Add query tests for LAN, tailnet, and public ClientID clients.

### Phase 2 — Put AdGuard first

1. Move CoreDNS to a private port.
2. Remove CoreDNS's default forwarding block.
3. Move AdGuard plain DNS to the LAN-facing port 53.
4. Add a LAN client group with a `sucha.foo` conditional upstream to CoreDNS.
5. Confirm that AdGuard logs the original LAN client.
6. Confirm that a public ClientID gets public `sucha.foo` answers.

### Phase 3 — Add the tailnet view

1. Serve a tailnet-only `sucha.foo` view with Tailscale A records.
2. Configure a Tailscale restricted nameserver for `sucha.foo`.
3. Keep Tailscale global DNS override disabled if native encrypted DNS remains the global resolver.
4. Verify that a tailnet client gets `100.124.66.105` for `quasar.sucha.foo`.
5. Verify that a non-tailnet public client gets the Cloudflare/public answer.

### Phase 4 — Replace rebuild-driven LAN records

Choose one:

- **Preferred:** replace the local CoreDNS authority with BIND and add per-host TSIG/RFC 2136 registration plus stale cleanup;
- **Smaller but bespoke:** generate client-scoped AdGuard `$dnsrewrite` rules from a central reconciler;
- **Broader device coverage:** add separate ASUSWRT and UniFi lease adapters;
- **One-service experiment:** prototype Technitium on alternate ports.

Do not remove CoreDNS until dynamic updates, wildcard precedence, stale cleanup, and rollback have passed tests.

## Verification matrix

| Test | LAN, no tailnet | Tailnet | Public, no tailnet |
|---|---|---|---|
| `quasar.sucha.foo` | LAN IP | Tailscale IP | Public/Cloudflare answer |
| `app.quasar.sucha.foo` | LAN path | Tailscale path | Public tunnel path |
| blocked ad domain | blocked | blocked by native public AdGuard profile | blocked |
| unknown local host | defined NXDOMAIN/public policy | defined NXDOMAIN/public policy | public answer or NXDOMAIN |
| AdGuard client identity | LAN CIDR/client | ClientID for global queries | ClientID |
| admin UI | private path only | Tailscale | not public without Access |

Also test:

- A, AAAA, CNAME, HTTPS/SVCB, and PTR behavior;
- DNSSEC validation on public names;
- stale registration removal;
- CoreDNS/authority failure;
- AdGuard failure;
- certificate renewal;
- Android Private DNS over DoT;
- Apple DoH/DoT profile;
- Tailscale with and without DNS acceptance;
- exit-node behavior if used;
- an external scan proving that plain recursion and the admin UI are not public.

## Final recommendation

Keep AdGuard Home and make it the DNS edge. Do not expose its administration UI publicly, but do expose a tightly allowlisted DoH/DoT hostname because native encrypted DNS is a stated requirement.

Do not try to obtain portable dynamic registration from the router's DNS behavior. ASUSWRT and UniFi can each be integrated, but not through one guaranteed interface. For the Nix-managed hosts, use authenticated host registration.

Use CoreDNS only as a transitional private authority. The reliability-first end state is **AdGuard Home plus a standard authoritative DDNS server**, with Tailscale split DNS selecting the tailnet view and public AdGuard clients falling through to normal public DNS. If one daemon later becomes more important than clear boundaries, prototype Technitium or a generated AdGuard-only rule set and compare their operational state and failure behavior before migrating.
