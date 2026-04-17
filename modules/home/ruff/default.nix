{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.home.ruff;
in
{
  options = {
    modules.home.ruff = {
      enable = lib.mkEnableOption "ruff" // {
        description = "Enable ruff";
        default = false;
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.ruff;
        description = "The ruff package to use";
      };

      settings = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Configuration written to $XDG_CONFIG_HOME/ruff/ruff.toml";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ruff = {
      enable = true;
      inherit (cfg) package settings;
    };
  };
}
