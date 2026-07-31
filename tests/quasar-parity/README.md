# Quasar parity baseline

`baseline.json` is the normalized runtime projection of the last deployable
Quasar configuration on `main`, commit
`23d6d3f2159581cc7a70ec1d12ea7d0ee90f1223`. This is the parent of the
denflake commit that moved the configuration under `oldflake/`.

Generate the snapshot from a worktree at that commit with:

```bash
nix eval --json --impure --expr '
  let
    flake = builtins.getFlake (toString ./.);
    project = import /path/to/nixfiles/tests/quasar-parity/projection.nix {
      lib = flake.inputs.nixpkgs.lib;
    };
  in
  project flake.nixosConfigurations.quasar.config
' | jq --sort-keys '
  walk(
    if type == "string" then
      gsub("/nix/store/[0-9a-z]{32}-"; "/nix/store/<hash>-")
    else
      .
    end
  )
' > baseline.json
```

The projection intentionally contains only generated secret metadata. It does
not contain decrypted secret values.

## Post-baseline source additions

The retained `oldflake/hosts/quasar` sources are the second migration input.
Their source-level differences from this snapshot are recorded in
`oldflake-delta.diff`; encrypted YAML is excluded from that diff.

## Intentional differences

- Quasar moves from `192.168.1.191` to its current address,
  `192.168.50.208`; its FQDN remains `quasar.sucha.foo`.
- The timezone moves from `America/Vancouver` to the accepted base default,
  `America/Edmonton`.
- The old Cachix agent declaration is not migrated.
- TCP firewall ports 25565 and 24454 for Minecraft are not migrated.
- Floating OCI image tags and current persisted paths remain unchanged during
  parity work.

The Nix configuration records image tags but not the digests currently pulled
on Quasar. Capture those digests manually before deployment; this migration
does not query the live host or pull containers.
