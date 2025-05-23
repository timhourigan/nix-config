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
        description = "Open the firewall for the Gatus service.";
      };
      configFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the Gatus configuration.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # WORKAROUND 1 - Ping requires root and the Gatus service in the module uses a dynamic
    # non-root user (DynamicUser=true). So change the user to root to allow ping.
    # https://github.com/TwiN/gatus/blob/dd839be918be5345c42be1cd4b94d97fc48def36/client/client.go#L269
    systemd.services.gatus.serviceConfig.User = lib.mkForce "root";
    systemd.services.gatus.serviceConfig.Group = lib.mkForce "root";
    # WORKAROUND 2 (Disabled) - If the configuration file is coming from a secret managed by sops-nix,
    # the Gatus service cannot access it because the module uses a Dynamic user (DynamicUser=true) and it
    # is not possible to give the transient user, permissions to read the secret file via sops-nix.
    # Instead, use systemd LoadCredential to load the secret file into the service at
    # /run/credentials/gatus.service/gatus_config.yaml (this only exists while the service is running).
    # Related issues:
    # - https://github.com/Mic92/sops-nix/issues/198
    # - https://github.com/Mic92/sops-nix/issues/412
    # - https://github.com/Mic92/sops-nix/issues/424
    # Disabled, as unnecessary because of WORKAROUND 1 above.
    # systemd.services.gatus.serviceConfig.LoadCredential = "gatus_config.yaml:${cfg.configFileSecret}";

    services.gatus = {
      enable = true;
      inherit (cfg) package;
      inherit (cfg) openFirewall;
      inherit (cfg) configFile;
    };
  };
}
