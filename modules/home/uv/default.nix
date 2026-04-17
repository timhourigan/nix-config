{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.home.uv;
in
{
  options = {
    modules.home.uv = {
      enable = lib.mkEnableOption "uv" // {
        description = "Enable uv";
        default = false;
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.uv;
        description = "The uv package to use";
      };

      settings = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Configuration written to $XDG_CONFIG_HOME/uv/uv.toml";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.uv = {
      enable = true;
      inherit (cfg) package settings;
    };
  };
}
