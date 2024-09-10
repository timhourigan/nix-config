{ lib, config, options, ... }:

# Home Assistant

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
        description = "Container image";
        type = lib.types.str;
        default = "ghcr.io/home-assistant/home-assistant:stable";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers = {
      backend = cfg.backend;
      containers.hass = {
        autoStart = true;
        volumes = [ "/var/lib/hass:/config" ];
        environment.TZ = cfg.environment.TZ;
        image = cfg.image;
        extraOptions = cfg.extraOptions;
      };
    };

    # Results in the creation of /var/lib/hass
    systemd.services."${config.virtualisation.oci-containers.backend}-hass".serviceConfig = {
      StateDirectory = "hass";
    };

    networking.firewall.allowedTCPPorts = [ 8123 ];
  };
}
