{ config, lib, ... }:

let
  cfg = config.modules.home.direnv;
in
{
  options = {
    modules.home.direnv = {
      enable = lib.mkEnableOption "Direnv" // {
        description = "Enable Direnv";
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      enableBashIntegration = true;
    };
  };
}
