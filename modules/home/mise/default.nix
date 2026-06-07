{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.home.mise;
  tomlFormat = pkgs.formats.toml { };
in
{
  options = {
    modules.home.mise = {
      enable = lib.mkEnableOption "mise" // {
        description = "Enable mise";
        default = false;
      };

      package = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = pkgs.mise;
        description = "The mise package to use (null to skip installing)";
      };

      globalConfig = lib.mkOption {
        inherit (tomlFormat) type;
        default = { };
        description = "Config written to $XDG_CONFIG_HOME/mise/config.toml";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.mise = {
      enable = true;
      inherit (cfg) package globalConfig;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
  };
}
