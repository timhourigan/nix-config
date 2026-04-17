{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.home.mise;
in
{
  options = {
    modules.home.mise = {
      enable = lib.mkEnableOption "mise" // {
        description = "Enable mise";
        default = false;
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.mise;
        description = "The mise package to use";
      };

      globalConfig = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Config written to $XDG_CONFIG_HOME/mise/config.toml";
      };

      settings = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Settings written to $XDG_CONFIG_HOME/mise/settings.toml";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.mise = {
      enable = true;
      inherit (cfg) package globalConfig settings;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
  };
}
