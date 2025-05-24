{ lib, config, options, ... }:

# https://github.com/lovelaze/nebula-sync

let
  cfg = config.modules.services.nebulaSync;
in
{
  options = {
    modules.services.nebulaSync = {
      enable = lib.mkEnableOption "Enable Nebula-Sync" // {
        description = "Enable Nebula-Sync service";
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
        default = "ghcr.io/lovelaze/nebula-sync:latest";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers = {
      inherit (cfg) backend;
      containers.nebula-sync = {
        # https://github.com/lovelaze/nebula-sync/pkgs/container/nebula-sync
        autoStart = true;
        inherit (cfg) environment;
        inherit (cfg) environmentFiles;
        inherit (cfg) image;
        inherit (cfg) extraOptions;
      };
    };
    systemd.services."${config.virtualisation.oci-containers.backend}-nebula-sync" = {
      # Start after network is up
      wantedBy = [ "multi-user.target" ];
    };
  };
}
