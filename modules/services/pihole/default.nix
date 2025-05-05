{ lib, config, options, ... }:

# https://docs.pi-hole.net

let
  cfg = config.modules.services.pihole;
  dnsPort = 53;
  httpPort = 80;
in
{
  options = {
    modules.services.pihole = {
      enable = lib.mkEnableOption "Enable Pi-Hole" // {
        description = "Enable Pi-Hole service";
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
      environmentFiles = lib.mkOption {
        description = "Environment file";
        type = lib.types.listOf lib.types.path;
        default = [ ];
      };
      extraOptions = lib.mkOption {
        description = "Extra options";
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
      image = lib.mkOption {
        description = "Container image";
        type = lib.types.str;
        default = "docker.io/pihole/pihole:latest";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers = {
      backend = cfg.backend;
      containers.pihole = {
        # https://github.com/pi-hole/docker-pi-hole
        autoStart = true;
        volumes = [ "/var/lib/pihole:/etc/pihole" ];
        environment = cfg.environment;
        environmentFiles = cfg.environmentFiles;
        image = cfg.image;
        extraOptions = cfg.extraOptions;
        ports = [
          "53:53/tcp"
          "53:53/udp"
          "80:80/tcp"
        ];
      };
    };
    systemd.services."${config.virtualisation.oci-containers.backend}-pihole" = {
      # Results in the creation of /var/lib/pihole
      # User and Group could be specified here but it would break the container,
      # as the container is running as root - See https://github.com/NixOS/nixpkgs/issues/207050
      # For now, the files will be owned as root
      serviceConfig = {
        StateDirectory = "pihole";
      };
      # Start after network is up
      wantedBy = [ "multi-user.target" ];
    };

    networking.firewall.allowedUDPPorts = [ dnsPort ];
    networking.firewall.allowedTCPPorts = [ dnsPort httpPort ];
  };
}
