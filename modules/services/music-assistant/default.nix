{
  inputs,
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

  # Web UI port - not covered by the upstream module's openFirewall
  webPort = 8095;
in
{
  # Replace the stable module with the one from nixpkgs-personal
  # which includes squeezelite/slimproto firewall port support.
  disabledModules = [ "services/audio/music-assistant.nix" ];
  imports = [
    "${inputs.nixpkgs-personal}/nixos/modules/services/audio/music-assistant.nix"
  ];

  options.modules.services.music-assistant = {
    enable = lib.mkEnableOption "Music Assistant";

    providers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "squeezelite"
        "spotify"
      ];
      description = "List of Music Assistant provider names to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.music-assistant = {
      enable = true;
      package = pkgs.personal.music-assistant;
      openFirewall = true;
      inherit (cfg) providers;
    };

    # Web UI port - not handled by upstream openFirewall
    networking.firewall.allowedTCPPorts = [ webPort ];
  };
}
