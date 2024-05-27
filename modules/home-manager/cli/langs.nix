{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # js
    nodejs

    # rust
    (fenix.complete.withComponents [
      "cargo"
      "clippy"
      "rust-src"
      "rustc"
      "rustfmt"
    ])
    rust-analyzer-nightly

    # python
    (python3.withPackages (ps: with ps; [ dbus-python pygobject3 requests ]))

    # other
    sqlite # for mcfly
  ];
}

