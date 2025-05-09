{ lib, config, options, ... }:

let
  cfg = config.modules.services.podman;
in
{
  options = {
    modules.services.podman = {
      enable = lib.mkEnableOption "Enable podman" // {
        description = "Enable podman backend";
        default = false;
      };
      dockerCompat = lib.mkOption {
        description = "Enable docker compatibility";
        type = lib.types.bool;
        default = false;
      };
      autoPrune = lib.mkOption {
        description = "Enable auto prune";
        type = lib.types.bool;
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation = {
      podman = {
        enable = true;
        dockerCompat = if cfg.dockerCompat then true else false;
        autoPrune.enable = if cfg.autoPrune then true else false;
        autoPrune.dates = if cfg.autoPrune then [ "weekly" ] else [ ];
        autoPrune.flags = if cfg.autoPrune then [ "--all" ] else [ ];
      };
    };
  };
}
