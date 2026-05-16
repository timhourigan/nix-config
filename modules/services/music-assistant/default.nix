{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:

# Music Assistant
# https://music-assistant.io/
# https://github.com/music-assistant/server

let
  cfg = config.modules.services.music-assistant;
in
{
  imports = [
    # Use the music-assistant module from unstable nixpkgs
    "${inputs.nixpkgs-unstable}/nixos/modules/services/audio/music-assistant.nix"
  ];

  # Disable the stable version of the module
  disabledModules = [
    "services/audio/music-assistant.nix"
  ];

  options = {
    modules.services.music-assistant = {
      enable = lib.mkEnableOption "Enable Music Assistant";
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.unstable.music-assistant;
        description = "The package to use";
      };
      extraOptions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra options to pass to the music-assistant executable";
      };
      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to open required ports for the configured providers";
      };
      providers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of provider names for which dependencies will be installed";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.music-assistant = {
      enable = true;
      inherit (cfg) package;
      inherit (cfg) extraOptions;
      inherit (cfg) openFirewall;
      inherit (cfg) providers;
    };
  };
}
