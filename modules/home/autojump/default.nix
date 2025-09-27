{ config, lib, options, ... }:

let
  cfg = config.modules.home.autojump;
in
{
  options = {
    modules.home.autojump = {
      enable = lib.mkEnableOption "Autojump" // {
        description = "Enable Autojump";
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.autojump = {
      enable = true;
      enableBashIntegration = true;
    };
  };
}
