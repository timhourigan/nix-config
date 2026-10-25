{
  inputs,
  lib,
  config,
  options,
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
  # Replace the stable module with the one from nixpkgs-unstable, which has
  # firewall support for more providers (e.g. squeezelite, spotify_connect).
  # TODO: Revert to stable once backported to a release
  disabledModules = [ "services/audio/music-assistant.nix" ];
  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/audio/music-assistant.nix"
  ];

  options.modules.services.music-assistant = {
    enable = lib.mkEnableOption "Music Assistant";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.unstable.music-assistant;
      description = "Package to use";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8095;
      description = ''
        Port for web interface. Music Assistant has no CLI flag for this,
        so it must match the port set in its own settings.
      '';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open firewall ports for the web interface, streaming and configured providers";
    };

    extraOptions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "--log-level"
        "DEBUG"
      ];
      description = "Extra options to pass to music-assistant, appended to the upstream defaults";
    };

    environmentFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      example = [ "/run/secrets/music_assistant_env" ];
      description = ''
        Environment files to pass to the service, e.g. for `MASS_APP_VAR_*`
        provider credentials such as `MASS_APP_VAR_SPOTIFY_CLIENT_ID`.
      '';
    };

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
    # The unstable module references these via stable pkgs, where they don't exist
    # TODO: Remove once available in a release
    nixpkgs.overlays = [
      (final: _prev: {
        inherit (final.unstable) airplay-cli go-librespot;
      })
    ];

    services.music-assistant = {
      enable = true;
      inherit (cfg) package openFirewall providers;
      extraOptions = options.services.music-assistant.extraOptions.default ++ cfg.extraOptions;
    };

    systemd.services.music-assistant = lib.mkMerge [
      {
        serviceConfig.EnvironmentFile = cfg.environmentFiles;
      }
      # Spotify playback via Soloist
      (lib.mkIf (lib.elem "spotify" cfg.providers) {
        # Audio capture via a private PulseAudio daemon
        path = [ pkgs.pulseaudio ];
        # libpulse for Music Assistant and Soloist
        environment.LD_LIBRARY_PATH = lib.makeLibraryPath [ pkgs.libpulseaudio ];
        serviceConfig = {
          # PulseAudio socket
          RestrictAddressFamilies = [ "AF_UNIX" ];
          # PulseAudio drops privileges on startup
          SystemCallFilter = lib.mkAfter [
            "setresuid"
            "capset"
          ];
        };
      })
    ];

    # Soloist is a generic Linux binary
    programs.nix-ld.enable = lib.mkIf (lib.elem "spotify" cfg.providers) true;

    # Upstream openFirewall only covers the stream and provider ports, so add the web interface port here
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
