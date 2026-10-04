{
  config,
  lib,
  pkgs,
  ...
}:

# Printing and scanning
# https://wiki.nixos.org/wiki/Printing
# https://wiki.nixos.org/wiki/Scanners
#
# Network printers are discovered via mDNS and used driverless (IPP Everywhere),
# with CUPS creating queues automatically - no per-printer configuration.
# Network scanners are accessed via eSCL/WSD using sane-airscan.

let
  cfg = config.modules.services.printing;
in
{
  options = {
    modules.services.printing = {
      enable = lib.mkEnableOption "printing and scanning" // {
        description = "Enable printing and scanning support";
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Printing
    services = {
      printing.enable = true;
      avahi = {
        enable = true;
        nssmdns4 = true;
        # For network printers/scanners
        openFirewall = true;
      };
    };

    # Scanning
    hardware.sane = {
      enable = true;
      extraBackends = [ pkgs.sane-airscan ];
      # sane-airscan replaces the built-in eSCL backend, avoiding duplicate devices
      disabledDefaultBackends = [ "escl" ];
    };

    environment.systemPackages = with pkgs; [
      naps2 # Scan to PDF, with OCR
      simple-scan # Document scanner
    ];
  };
}
