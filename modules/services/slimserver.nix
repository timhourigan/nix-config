{ lib, config, options, pkgs, ... }:

# SlimServer aka Logitech Media Server (LMS) aka Lyrion
# https://mynixos.com/options/services.slimserver
# https://lyrion.org/

let
  cfg = config.modules.services.slimserver;
  port = 9000;
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
      package = cfg.package;
      dataDir = cfg.dataDir;
    };

    networking.firewall.allowedTCPPorts = [ port ];
  };
}
