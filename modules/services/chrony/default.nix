{ lib, config, ... }:

# Chrony NTP client and server
# https://mynixos.com/options/services.chrony

# Test with:
# nix shell nixpkgs#ntp -c ntpdate -q 192.168.X.X

let
  cfg = config.modules.services.chrony;
in
{
  options = {
    modules.services.chrony = {
      enable = lib.mkEnableOption "Chrony" // {
        description = "Enable the Chrony NTP client";
        default = false;
      };
      extraConfig = lib.mkOption {
        description = "Extra configuration to be passed to chronyd";
        type = lib.types.str;
        default = "";
      };
      servers = lib.mkOption {
        description = "List of NTP servers to use";
        type = lib.types.listOf lib.types.str;
        default = [ "0.pool.ntp.org" "1.pool.ntp.org" "2.pool.ntp.org" "3.pool.ntp.org" ];
      };
      serverOption = lib.mkOption {
        description = "Server directive option";
        type = lib.types.str;
        default = "iburst";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.chrony = {
      enable = true;
      inherit (cfg) extraConfig;
      inherit (cfg) servers;
      inherit (cfg) serverOption;
    };

    # If extraConfig contains `allow` assume external access and update the firewall
    networking.firewall.allowedUDPPorts = if (lib.strings.hasInfix "allow" cfg.extraConfig) then [ 123 ] else [ ];
  };
}
