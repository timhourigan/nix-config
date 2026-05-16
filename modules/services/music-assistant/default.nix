{
  lib,
  config,
  ...
}:

# Music Assistant
# https://music-assistant.io/
# https://github.com/music-assistant/server

let
  cfg = config.modules.services.music-assistant;
  webPort = 8095;
  streamPort = 8097;
  slimprotoCliPort = 9090;
  slimprotoJsonRpcPort = 9000;
  slimprotoDiscoveryPort = 3483;
in
{
  options = {
    modules.services.music-assistant = {
      enable = lib.mkEnableOption "Enable Music Assistant" // {
        description = "Enable Music Assistant service";
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
        default = "ghcr.io/music-assistant/server:latest";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers = {
      inherit (cfg) backend;
      containers.music-assistant = {
        autoStart = true;
        volumes = [ "/var/lib/music-assistant:/data" ];
        inherit (cfg) environment;
        inherit (cfg) image;
        inherit (cfg) extraOptions;
      };
    };

    systemd.services."${config.virtualisation.oci-containers.backend}-music-assistant" = {
      serviceConfig = {
        StateDirectory = "music-assistant";
      };
      wants = [ "nss-lookup.target" ];
      after = [ "nss-lookup.target" ];
    };

    networking.firewall.allowedTCPPorts = [
      webPort
      streamPort
      slimprotoCliPort
      slimprotoJsonRpcPort
    ];
    networking.firewall.allowedUDPPorts = [
      slimprotoDiscoveryPort
    ];
  };
}
