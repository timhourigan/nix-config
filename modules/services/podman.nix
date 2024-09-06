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
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation = {
      podman = {
        enable = true;
        dockerCompat = if cfg.dockerCompat then true else false;
      };
    };
  };
}
