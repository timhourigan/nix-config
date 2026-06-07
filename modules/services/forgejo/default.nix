{ lib, config, ... }:

# Forgejo - A software forge
# https://mynixos.com/nixpkgs/options/services.forgejo

let
  cfg = config.modules.services.forgejo;
in
{
  options = {
    modules.services.forgejo = {
      enable = lib.mkEnableOption "Forgejo" // {
        description = "Enable Forgejo, a software forge";
        default = false;
      };
      domain = lib.mkOption {
        description = "Domain name for Forgejo";
        type = lib.types.str;
        default = "localhost";
      };
      stateDir = lib.mkOption {
        description = "Forgejo data directory";
        type = lib.types.str;
        default = "/var/lib/forgejo";
      };
      httpPort = lib.mkOption {
        description = "HTTP port for Forgejo to listen on";
        type = lib.types.port;
        default = 3000;
      };
      settings = lib.mkOption {
        description = "Additional freeform settings for Forgejo (merged into services.forgejo.settings)";
        type = lib.types.attrs;
        default = { };
      };
      database = {
        type = lib.mkOption {
          description = "Database engine to use (sqlite3, mysql, postgres)";
          type = lib.types.enum [
            "sqlite3"
            "mysql"
            "postgres"
          ];
          default = "sqlite3";
        };
        passwordFile = lib.mkOption {
          description = "Path to a file containing the database password";
          type = lib.types.nullOr lib.types.path;
          default = null;
        };
      };
      openFirewall = lib.mkOption {
        description = "Whether to open the HTTP port in the firewall";
        type = lib.types.bool;
        default = false;
      };
      lfs.enable = lib.mkOption {
        description = "Enable Git LFS support";
        type = lib.types.bool;
        default = false;
      };
      dump = {
        enable = lib.mkOption {
          description = "Enable periodic database dumps";
          type = lib.types.bool;
          default = false;
        };
        interval = lib.mkOption {
          description = "Interval for dump timer (systemd calendar format)";
          type = lib.types.str;
          default = "04:31";
        };
        age = lib.mkOption {
          description = "Age of backup files to keep before cleanup (tmpfiles.d format)";
          type = lib.types.str;
          default = "4w";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.forgejo = {
      enable = true;
      inherit (cfg) stateDir;
      database = {
        inherit (cfg.database) type;
        inherit (cfg.database) passwordFile;
      };
      lfs.enable = cfg.lfs.enable;
      dump = {
        inherit (cfg.dump) enable;
        inherit (cfg.dump) interval;
        inherit (cfg.dump) age;
      };
      settings = lib.mkMerge [
        {
          server = {
            DOMAIN = cfg.domain;
            HTTP_PORT = cfg.httpPort;
          };
        }
        cfg.settings
      ];
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.httpPort ];
  };
}
