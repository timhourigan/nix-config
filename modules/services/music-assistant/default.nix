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
#
# Uses the NixOS module from nixpkgs-unstable with a patched aioslimproto
# to fix _handle_serverstatus() TypeError with PiCorePlayer.
# https://github.com/music-assistant/aioslimproto/issues/XXX

let
  cfg = config.modules.services.music-assistant;

  # Import unstable nixpkgs with a patched aioslimproto.
  # aioslimproto 3.1.8 has a bug where _handle_serverstatus() doesn't accept
  # extra positional args sent by PiCorePlayer, causing a TypeError.
  # We patch the python package via overlay so the fix propagates into the
  # provider dependency chain (aioslimproto is a separate store path from
  # music-assistant, so patching music-assistant's $out doesn't help).
  unstablePkgs = import inputs.nixpkgs-unstable {
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

  # Slimproto ports not covered by the upstream module's openFirewall
  webPort = 8095;
  slimprotoCliPort = 9090;
  slimprotoJsonRpcPort = 9000;
  slimprotoDiscoveryPort = 3483; # TCP (control) + UDP (discovery)
in
{
  # Replace the stable module (which doesn't exist in 25.11) with the unstable one
  disabledModules = [ "services/audio/music-assistant.nix" ];
  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/audio/music-assistant.nix"
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

    openSlimprotoFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open Slimproto ports (CLI, JSON-RPC, discovery) in the firewall.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Use the patched package from unstable
    services.music-assistant = {
      enable = true;
      package = unstablePkgs.music-assistant;
      inherit (cfg) providers;
    };

    # Open Slimproto and web UI ports (not handled by upstream openFirewall)
    networking.firewall = lib.mkIf cfg.openSlimprotoFirewall {
      allowedTCPPorts = [
        webPort
        slimprotoCliPort
        slimprotoJsonRpcPort
        slimprotoDiscoveryPort
      ];
      allowedUDPPorts = [
        slimprotoDiscoveryPort
      ];
    };
  };
}
