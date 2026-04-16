{ config, lib, ... }:

let
  cfg = config.modules.home.granted;
in
{
  options = {
    modules.home.granted = {
      enable = lib.mkEnableOption "granted" // {
        description = "Enable Granted";
        default = false;
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.granted;
        description = "The granted package to use";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.granted = {
      enable = true;
      inherit (cfg) package;
      enableZshIntegration = true;
    };
  };
}
