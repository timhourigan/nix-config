{
  lib,
  config,
  ...
}:

let
  cfg = config.modules.services.mosquitto;
  port = 1883;
in
{
  options = {
    modules.services.mosquitto = {
      enable = lib.mkEnableOption "Enable Mosquitto" // {
        description = "Enable Mosquitto MQTT broker";
        default = false;
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

    networking.firewall.allowedTCPPorts = [
      port
    ];
  };
}
