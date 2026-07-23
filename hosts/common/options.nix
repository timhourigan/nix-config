{ lib, ... }:

{
  options = {
    custom = {
      defaultUser = lib.mkOption {
        type = lib.types.str;
        default = "timh";
        description = "Default user";
      };
      internalDomain = lib.mkOption {
        type = lib.types.str;
        default = "rc.home";
        description = "Internal domain";
      };
      images = {
        pihole = lib.mkOption {
          type = lib.types.str;
          default = "docker.io/pihole/pihole:2026.07.2";
          description = "Pi-hole container image";
        };
        # https://github.com/home-assistant/core/releases
        homeAssistant = lib.mkOption {
          type = lib.types.str;
          default = "ghcr.io/home-assistant/home-assistant:2026.7.3";
          description = "Home Assistant container image";
        };
        nebulaSync = lib.mkOption {
          type = lib.types.str;
          default = "ghcr.io/lovelaze/nebula-sync:v0.11.2";
          description = "Nebula-Sync container image";
        };
      };
    };
  };
}
