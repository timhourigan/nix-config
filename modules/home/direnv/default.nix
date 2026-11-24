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

      nixDirenv = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to install nix-direnv for cached use_nix and use_flake";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      nix-direnv.enable = cfg.nixDirenv;
    };
  };
}
