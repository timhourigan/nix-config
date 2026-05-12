{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.home.atuin;
in
{
  options = {
    modules.home.atuin = {
      enable = lib.mkEnableOption "Atuin" // {
        description = "Enable Atuin";
        default = false;
      };
      package = lib.mkOption {
        description = "Atuin package to use";
        type = lib.types.package;
        default = pkgs.atuin;
      };
      enableBashIntegration = lib.mkOption {
        description = "Enable Bash integration";
        type = lib.types.bool;
        default = true;
      };
      enableZshIntegration = lib.mkOption {
        description = "Enable Zsh integration";
        type = lib.types.bool;
        default = true;
      };
      flags = lib.mkOption {
        description = "Flags to append to the shell hook";
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
      forceOverwriteSettings = lib.mkOption {
        description = "Force overwriting of the Atuin configuration file";
        type = lib.types.bool;
        default = false;
      };
      themes = lib.mkOption {
        description = "Theme definitions written to atuin themes directory";
        type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
        default = { };
      };
      settings = lib.mkOption {
        description = "Configuration written to config.toml";
        type = lib.types.attrsOf lib.types.anything;
        default = { };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.atuin = {
      enable = true;
      inherit (cfg) package;
      inherit (cfg) enableBashIntegration;
      inherit (cfg) enableZshIntegration;
      inherit (cfg) flags;
      inherit (cfg) forceOverwriteSettings;
      inherit (cfg) themes;
      inherit (cfg) settings;
    };
  };
}
