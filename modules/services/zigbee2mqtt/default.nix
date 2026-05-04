{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.modules.services.zigbee2mqtt;
  port = 8124;
in
{
  options = {
    modules.services.zigbee2mqtt = {
      enable = lib.mkEnableOption "Enable Zigbee2MQTT" // {
        description = "Enable Zigbee2MQTT service";
        default = false;
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.zigbee2mqtt;
        description = "Zigbee2MQTT package to use";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.zigbee2mqtt = {
      inherit (cfg) package;
      enable = true;
      # https://www.zigbee2mqtt.io/guide/configuration/
      settings = {
        advanced = {
          channel = 25;
          last_seen = "ISO_8601_local";
          transmit_power = 20;
        };
        availability = {
          enabled = true;
          active.timeout = 10;
          passive.timeout = 1500;
        };
        frontend = {
          inherit port;
          package = "zigbee2mqtt-windfront";
        };
        homeassistant = {
          # https://www.zigbee2mqtt.io/guide/configuration/homeassistant.html
          enabled = true;
          discovery_topic = "homeassistant";
          status_topic = "homeassistant/status";
          # Version 2.0.0 removes action sensors (sensor.*_action entities)
          # https://github.com/Koenkk/zigbee2mqtt/discussions/24198
          # Options:
          # 1. Use MQTT triggers, which use device ids and so not desired
          # https://www.zigbee2mqtt.io/guide/usage/integrations/home_assistant.html#via-mqtt-device-trigger-recommended
          # 2. Restore action sensors in 2.0.0 - Going with this for now:
          legacy_action_sensor = true;
          # 3. Migrate automations to experimental event type:
          # - Adding event.*action entities to enable testing
          # - One side effect is that automations may need to get more complicated,
          #   as restarts of z2m result in the event being seen again by HA
          #   and so automations might need more checks
          # experimental_event_entities = true;
        };
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

    systemd = {
      services.zigbee2mqtt = {
        serviceConfig = {
          # z2m stops (with exit 0) when the adapter disconnects or isn't
          # available yet, so restart "always"
          Restart = lib.mkForce "always";
          RestartSec = "10";
        };
        # Ensure network is up before starting
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
      };
    };

    networking.firewall.allowedTCPPorts = [
      port
    ];
  };
}
