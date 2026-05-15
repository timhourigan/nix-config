{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.home.atuin;

  # Theme definitions

  ansi-terminal = {
    theme = {
      name = "ansi-terminal";
    };
    colors = {
      AlertInfo = "@green";
      AlertWarn = "@yellow";
      AlertError = "@dark_magenta"; # also used for selected line
      Annotation = "@cyan";
      Base = "@light_grey";
      Guidance = "@dark_grey";
      Important = "@dark_blue";
      Title = "@blue";
      Muted = "@dark_magenta";
    };
  };

  # Catppuccin themes - see
  # https://github.com/catppuccin/atuin/tree/main/themes

  catppuccin-mocha-teal = {
    theme = {
      name = "catppuccin-mocha-teal";
    };
    colors = {
      AlertInfo = "#a6e3a1";
      AlertWarn = "#fab387";
      AlertError = "#f38ba8";
      Annotation = "#94e2d5";
      Base = "#cdd6f4";
      Guidance = "#9399b2";
      Important = "#f38ba8";
      Title = "#94e2d5";
    };
  };

  catppuccin-mocha-mauve = {
    theme = {
      name = "catppuccin-mocha-mauve";
    };
    colors = {
      AlertInfo = "#a6e3a1";
      AlertWarn = "#fab387";
      AlertError = "#f38ba8";
      Annotation = "#cba6f7";
      Base = "#cdd6f4";
      Guidance = "#9399b2";
      Important = "#f38ba8";
      Title = "#cba6f7";
    };
  };

  catppuccin-mocha-red = {
    theme = {
      name = "catppuccin-mocha-red";
    };
    colors = {
      AlertInfo = "#a6e3a1";
      AlertWarn = "#fab387";
      AlertError = "#f38ba8";
      Annotation = "#f38ba8";
      Base = "#cdd6f4";
      Guidance = "#9399b2";
      Important = "#f38ba8";
      Title = "#f38ba8";
    };
  };

  catppuccin-mocha-rosewater = {
    theme = {
      name = "catppuccin-mocha-rosewater";
    };
    colors = {
      AlertInfo = "#a6e3a1";
      AlertWarn = "#fab387";
      AlertError = "#f38ba8";
      Annotation = "#f5e0dc";
      Base = "#cdd6f4";
      Guidance = "#9399b2";
      Important = "#f38ba8";
      Title = "#f5e0dc";
    };
  };
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
        default = {
          inherit ansi-terminal;
          inherit catppuccin-mocha-mauve;
          inherit catppuccin-mocha-red;
          inherit catppuccin-mocha-rosewater;
          inherit catppuccin-mocha-teal;
        };
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
