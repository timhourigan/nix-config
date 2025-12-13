{ config, lib, ... }:

let
  cfg = config.modules.home.gh;
in
{
  options = {
    modules.home.gh = {
      enable = lib.mkEnableOption "gh" // {
        description = "Enable gh";
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.gh = {
      enable = true;
      gitCredentialHelper = {
        enable = true;
      };
      settings = {
        editor = "vim";
      };
    };
  };
}
