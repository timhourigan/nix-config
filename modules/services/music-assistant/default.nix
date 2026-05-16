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

  # Import unstable nixpkgs for the music-assistant package
  unstablePkgs = import inputs.nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };

  # Patch aioslimproto's _handle_serverstatus to accept extra positional args.
  # The upstream package.nix creates its own python override chain, making it
  # impractical to inject a patched aioslimproto via python3 packageOverrides.
  # Instead, we patch the installed file directly in postFixup.
  patchedMusicAssistant = unstablePkgs.music-assistant.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      find $out -path '*/aioslimproto/cli.py' -exec \
        sed -i '/def _handle_serverstatus/,/\*\*kwargs/ {
          /limit: int = 2,/a\        *args,
        }' {} \;
    '';
  });

  # Slimproto ports not covered by the upstream module's openFirewall
  webPort = 8095;
  slimprotoCliPort = 9090;
  slimprotoJsonRpcPort = 9000;
  slimprotoDiscoveryPort = 3483;
in
{
  # Replace the stable module (which doesn't exist in 25.11) with the unstable one
  disabledModules = [ "services/audio/music-assistant.nix" ];
  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/audio/music-assistant.nix"
  ];

  options.modules.services.music-assistant = {
    enable = lib.mkEnableOption "Music Assistant";

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
      package = patchedMusicAssistant;
    };

    # Open Slimproto and web UI ports (not handled by upstream openFirewall)
    networking.firewall = lib.mkIf cfg.openSlimprotoFirewall {
      allowedTCPPorts = [
        webPort
        slimprotoCliPort
        slimprotoJsonRpcPort
      ];
      allowedUDPPorts = [
        slimprotoDiscoveryPort
      ];
    };
  };
}
