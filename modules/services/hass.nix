{ lib, config, options, ... }:

let
  cfg = config.modules.services.hass;
in
{
  options = {
    modules.services.hass = {
      enable = lib.mkEnableOption "Enable Home Assistant" // {
        description = "Enable Home Assistant service";
        default = false;
      };
      backend = lib.mkOption {
        description = "Container backend";
        type = lib.types.str;
        default = "podman";
      };
      environment = lib.mkOption {
        description = "Environment variables";
        type = lib.types.attrsOf lib.types.str;
        default = {
          TZ = "Europe/Dublin";
        };
      };
      extraOptions = lib.mkOption {
        description = "Extra options";
        type = lib.types.listOf lib.types.str;
        default = [];
      };
      image = lib.mkOption {
        description = "Home Assistant image";
        type = lib.types.str;
        default = "ghcr.io/home-assistant/home-assistant:stable";
      };
      volumes = lib.mkOption {
        description = "Volumes to mount";
        type = lib.types.listOf lib.types.str;
        default = [ "home-assistant:/config" ];
      };
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers = {
      backend = cfg.backend;
      containers.homeassistant = {
        autoStart = true;
        volumes = cfg.volumes;
        environment.TZ = cfg.environment.TZ;
        image = cfg.image;
        extraOptions = cfg.extraOptions;
      };
    };

    networking.firewall.allowedTCPPorts = [ 8123 ];
  };
}
