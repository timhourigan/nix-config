{ lib, config, options, pkgs, ... }:

# SlimServer aka Logitech Media Server (LMS) aka Lyrion
# https://mynixos.com/options/services.slimserver
# https://lyrion.org/

let
  cfg = config.modules.services.slimserver;
  slimServerPort = 9000;
  slimServerCliPort = 9090;
  playerPort = 3483;
in
{
  options = {
    modules.services.slimserver = {
      enable = lib.mkEnableOption "Enable SlimServer";
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.slimserver;
        description = "The package to use";
      };
      dataDir = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/slimserver";
        description = "The directory to store the data";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.slimserver = {
      enable = true;
      inherit (cfg) package;
      inherit (cfg) dataDir;
    };
    systemd.services.slimserver = {
      # Ensure network is up before starting
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    # WORKAROUND - Try to avoid issues on boot by delaying startup by 90 seconds
    systemd.timers.slimserver = {
      partOf = [ "slimserver.service" ];
      wantedBy = [ "timers.target" ];
      timerConfig.OnBootSec = "90";
    };

    networking.firewall.allowedTCPPorts = [ slimServerPort slimServerCliPort playerPort ];
    networking.firewall.allowedUDPPorts = [ slimServerPort slimServerCliPort playerPort ];
  };
}
