{ config, lib, pkgs, ... }:

let
  cfg = config.modules.home.git;
in
{
  options = {
    modules.home.git = {
      enable = lib.mkEnableOption "git" // {
        description = "Enable git";
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      package = pkgs.gitFull;
      enable = true;
      settings = {
        aliases = {
          ci = "commit";
          co = "checkout";
          br = "branch";
          st = "status";
          pub = "push origin -u";
        };
        extraConfig = { credential = { helper = "libsecret"; }; };
        user = {
          name = "Tim Hourigan";
          email = "1819176+timhourigan@users.noreply.github.com";
        };
      };
    };
  };
}
