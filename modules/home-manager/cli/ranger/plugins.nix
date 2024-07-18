{ config, lib, pkgs, ... }:

let
  inherit (pkgs) fetchFromGitHub;
  cfg = config.cli;
in {
  config = lib.mkIf cfg.enable {
    programs.ranger.plugins = [
      {
        name = "ranger-archives";
        src = fetchFromGitHub {
          owner = "maximtrp";
          repo = "ranger-archives";
          rev = "b4e136b24fdca7670e0c6105fb496e5df356ef25";
          sha256 = "sha256-QJu5G2AYtwcaE355yhiG4wxGFMQvmBWvaPQGLsi5x9Q=";
        };
      }
      {
        name = "devicons2";
        src = fetchFromGitHub {
          owner = "cdump";
          repo = "ranger-devicons2";
          rev = "f7877aa0dd8caa1d498d935f6f49e57a4fc591e2";
          sha256 = "sha256-OMMQW/mn8J8mki41TD/7/CWaDFgp/zT7B2hfTH/m0Ug=";
        };
      }
      {
        name = "ranger-fzf-filter";
        src = fetchFromGitHub {
          owner = "MuXiu1997";
          repo = "ranger-fzf-filter";
          rev = "bf16de2e4ace415b685ff7c58306d0c5146f9f43";
          sha256 = "sha256-4J0OLNeXPKvS7WvpgGWJPOeecXFG0QJ5/GbM3qogFTk=";
        };
      }
      {
        name = "ranger-zoxide";
        src = fetchFromGitHub {
          owner = "jchook";
          repo = "ranger-zoxide";
          rev = "281828de060299f73fe0b02fcabf4f2f2bd78ab3";
          sha256 = "sha256-JEuyYSVa1NS3aftezEJx/k19lwwzf7XhqBCL0jH6VT4=";
        };
      }
    ];
  };
}
