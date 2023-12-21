{ pkgs, ... }: {
  imports = [
    ./bash.nix
    ./bat.nix
    ./direnv.nix
    ./fish.nix
    ./gh.nix
    ./git.nix
    ./gpg.nix
    ./jujutsu.nix
    ./lyrics.nix
    ./nix-index.nix
    ./pfetch.nix
    ./ranger.nix
    ./screen.nix
    ./shellcolor.nix
    ./ssh.nix
    ./starship.nix
    ./xpo.nix
  ];
  home.packages = with pkgs; [
    comma # Install and run programs by sticking a , before them
    distrobox # Nice escape hatch, integrates docker images with my environment

    bc # Calculator
    bottom # System viewer
    ncdu # TUI disk usage
    eza # Better ls
    ripgrep # Better grep
    fd # Better find
    httpie # Better curl
    diffsitter # Better diff
    jq # JSON pretty printer and manipulator
    trekscii # Cute startrek cli printer
    timer # To help with my ADHD paralysis

    nil # Nix LSP
    nixfmt # Nix formatter
    nix-inspect # See which pkgs are in your PATH

    ltex-ls # Spell checking LSP

    tly # Tally counter
  ];
}
