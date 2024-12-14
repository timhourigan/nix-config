{ lib, config, pkgs, options, ... }:

# Home Assistant
# - Mosquitto service
# - zigbee2mqtt service
# - Home Assistant container

let
  cfg = config.modules.services.hass;
  hassPort = 8123;
  z2mPort = 8124;
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
    services.mosquitto = {
      enable = true;
      listeners = [{
        address = "127.0.0.1";
        settings.allow_anonymous = true;
        acl = [ "topic readwrite #" ];
      }];
    };

    # zigbee2mqtt service
    services.zigbee2mqtt = {
      package = pkgs.unstable.zigbee2mqtt;
      enable = true;
      # https://www.zigbee2mqtt.io/guide/configuration/
      settings = {
        advanced = {
          channel = 25;
          last_seen = "ISO_8601_local";
          transmit_power = 20;
        };
        availability = {
          active.timeout = 10;
          passive.timeout = 1500;
        };
        frontend.port = z2mPort;
        homeassistant = true;
        mqtt = {
          server = "mqtt://localhost:1883";
          base_topic = "zigbee2mqtt";
        };
        serial = {
          port = "tcp://192.168.90.100:6638";
          baudrate = 115200;
          adapter = "ember";
          rtscts = false;
        };
      };
    };

    # Home Assistant container
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
    # User and Group could be specified here but it would breake the container,
    # as the container is running as root - See https://github.com/NixOS/nixpkgs/issues/207050
    # For now, the files will be owned as root
    systemd.services."${config.virtualisation.oci-containers.backend}-hass".serviceConfig = {
      StateDirectory = "hass";
    };

    networking.firewall.allowedTCPPorts = [ hassPort z2mPort ];
  };
}
