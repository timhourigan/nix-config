{
  lib,
  config,
  ...
}:

# Home Assistant

let
  cfg = config.modules.services.hass;
  hassPort = 8123;
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
        default = [ ];
      };
      image = lib.mkOption {
        description = "Container image";
        type = lib.types.str;
        default = "ghcr.io/home-assistant/home-assistant:stable";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Mosquitto service
    modules.services.mosquitto.enable = true;

    # zigbee2mqtt service
    modules.services.zigbee2mqtt.enable = true;

    # Home Assistant container
    virtualisation.oci-containers = {
      inherit (cfg) backend;
      containers.hass = {
        autoStart = true;
        volumes = [ "/var/lib/hass:/config" ];
        environment.TZ = cfg.environment.TZ;
        inherit (cfg) image;
        inherit (cfg) extraOptions;
      };
    };

    systemd.services."${config.virtualisation.oci-containers.backend}-hass" = {
      # Results in the creation of /var/lib/hass
      # User and Group could be specified here but it would break the container,
      # as the container is running as root - See https://github.com/NixOS/nixpkgs/issues/207050
      # For now, the files will be owned as root
      serviceConfig = {
        StateDirectory = "hass";
      };
      # Ensure DNS is available before starting
      wants = [ "nss-lookup.target" ];
      after = [ "nss-lookup.target" ];
    };
    networking.firewall.allowedTCPPorts = [
      hassPort
    ];
  };
}
