{ lib, config, options, pkgs, ... }:

# Gatus health check aggregator
# https://mynixos.com/nixpkgs/options/services.gatus

let
  cfg = config.modules.services.gatus;
in
{
  options = {
    modules.services.gatus = {
      enable = lib.mkEnableOption "Gatus" // {
        description = "Enable the Gatus health check aggregator";
        default = false;
      };
      package = lib.mkPackageOption pkgs "gatus" { };
      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Open the firewall for the Gatus service.
        '';
      };
      configFileSecret = lib.mkOption {
        type = lib.types.path;
        default = config.sops.secrets."gatus".path;
        description = ''
          Path to the Gatus configuration file secret.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # WORKAROUND - The configuration file is coming from a secret managed by sops-nix.
    # As the Gatus service module uses a Dynamic user (DynamicUser=true), it is not possible
    # to give the transient user permissions to read the secret file via sops-nix.
    # Instead, use systemd LoadCredential to load the secret file into the service at
    # /run/credentials/gatus.service/gatus_config.yaml (this only exists while the service is running).
    # Related issues:
    # - https://github.com/Mic92/sops-nix/issues/198
    # - https://github.com/Mic92/sops-nix/issues/412
    # - https://github.com/Mic92/sops-nix/issues/424
    # systemd.services.gatus.serviceConfig.LoadCredential = "gatus_config.yaml:${config.sops.secrets."gatus".path}";
    systemd.services.gatus.serviceConfig.LoadCredential = "gatus_config.yaml:${cfg.configFileSecret}";

    services.gatus = {
      enable = true;
      package = cfg.package;
        openFirewall = cfg.openFirewall;
      # See WORKAROUND above
      configFile = "/run/credentials/gatus.service/gatus_config.yaml";
    };
  };
}
