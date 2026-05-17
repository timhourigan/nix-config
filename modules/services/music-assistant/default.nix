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

  # WORKAROUND - https://github.com/music-assistant/aioslimproto/pull/528
  #
  # Import nixpkgs-personal with a patched aioslimproto.
  # aioslimproto 3.1.8 has a bug where _handle_serverstatus() doesn't accept
  # extra positional args sent by PiCorePlayer, causing a TypeError.
  # We patch the python package via overlay so the fix propagates into the
  # provider dependency chain (aioslimproto is a separate store path from
  # music-assistant, so patching music-assistant's $out doesn't help).
  patchedPkgs = import inputs.nixpkgs-personal {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
    overlays = [
      (_final: prev: {
        # Use pythonPackagesExtensions (not python3.override { packageOverrides })
        # because music-assistant's package.nix calls python3.override with its
        # own packageOverrides, which replaces any we set. Extensions survive.
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (_pfinal: pprev: {
            aioslimproto = pprev.aioslimproto.overridePythonAttrs (old: {
              postPatch = (old.postPatch or "") + ''
                sed -i '/def _handle_serverstatus/,/\*\*kwargs/ {
                  /limit: int = 2,/a\        *args,
                }' aioslimproto/cli.py
              '';
            });
          })
        ];
      })
    ];
  };

  # Web UI port - not covered by the upstream module's openFirewall
  webPort = 8095;
in
{
  # Replace the stable module (which doesn't exist in 25.11) with the one from
  # nixpkgs-personal which includes squeezelite/slimproto firewall port support.
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
    # Use the patched package
    services.music-assistant = {
      enable = true;
      package = patchedPkgs.music-assistant;
      openFirewall = true;
      inherit (cfg) providers;
    };

    # Web UI port - not handled by upstream openFirewall
    networking.firewall.allowedTCPPorts = [ webPort ];
  };
}
