{
  lib,
  config,
  ...
}:

# Home Assistant
# - Mosquitto service
# - Home Assistant container

let
  cfg = config.modules.services.hass;
  hassPort = 8123;
  mosquittoPort = 1883;
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
      listeners = [
        {
          # Trust local - Test with:
          # nix shell nixpkgs#mosquitto --command mosquitto_pub -h 127.0.0.1 -t 'test/topic' -m 'hello world'
          address = "127.0.0.1";
          settings.allow_anonymous = true;
          acl = [ "topic readwrite #" ];
        }
        # TODO - Below is no longer generic
        {
          # Require auth for non-local - Test with:
          # nix shell nixpkgs#mosquitto --command mosquitto_pub -h <ip-address> -t '<topic>' -m 'hello world' -u <user> -P <password>
          address = "192.168.90.10";
          settings.allow_anonymous = false;

          # Valetudo Larry
          users.larry = {
            # Not necessary to add `topic` here, it ends up in the acl automatically.
            # See `/etc/mosquitto/acl-X.conf`
            # Needs access to Home Assistant topic and it's own topic
            acl = [
              "readwrite homeassistant/#"
              "readwrite valetudo/Larry/#"
            ];
            passwordFile = "${config.sops.secrets."mqtt/valetudo/larry/password".path}";
          };
          # Valetudo Harry
          users.harry = {
            # Needs access to Home Assistant topic and it's own topic
            acl = [
              "readwrite homeassistant/#"
              "readwrite valetudo/Harry/#"
            ];
            passwordFile = "${config.sops.secrets."mqtt/valetudo/harry/password".path}";
          };
        }
      ];
    };

    # Service can return `Error: Cannot assign requested address` on boot
    # so restart "always"
    systemd = {
      services.mosquitto = {
        serviceConfig = {
          Restart = lib.mkForce "always";
          RestartSec = "10";
        };
      };
    };

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
      mosquittoPort
    ];
  };
}
