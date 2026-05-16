{
  lib,
  config,
  pkgs,
  ...
}:

# Music Assistant
# https://music-assistant.io/
# https://github.com/music-assistant/server

let
  cfg = config.modules.services.music-assistant;
in
{
  options = {
    modules.services.music-assistant = {
      enable = lib.mkEnableOption "Enable Music Assistant";
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.music-assistant;
        description = "The package to use";
      };
      extraOptions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra options to pass to the music-assistant executable";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.music-assistant = {
      enable = true;
      inherit (cfg) package;
      inherit (cfg) extraOptions;
    };

    networking.firewall.allowedTCPPorts = [
      8095 # Web UI
      8097 # Stream port
      9000 # Slimproto JSON-RPC
      9090 # Slimproto CLI
    ];
    networking.firewall.allowedUDPPorts = [
      3483 # Slimproto discovery
    ];
  };
}
