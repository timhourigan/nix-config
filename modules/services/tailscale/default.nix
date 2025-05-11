{ lib, config, options, ... }:

# https://wiki.nixos.org/wiki/Tailscale

let
  cfg = config.modules.services.tailscale;
in
{
  options = {
    modules.services.tailscale = {
      enable = lib.mkEnableOption "tailscale" // {
        description = "Enable tailscale";
        default = false;
      };
      enableDNS = lib.mkOption {
        description = "Enable DNS";
        type = lib.types.bool;
        default = true;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      # DNS is enabled by default
      extraUpFlags = if cfg.enableDNS then [ ] else [ "--accept-dns=false" ];
    };

    # WORKAROUND - Tailscale causing NetworkManager-wait-online to fail on start
    # https://github.com/NixOS/nixpkgs/issues/180175
    systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
  };
}
