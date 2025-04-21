{ ... }:

{
  # Remote Desktop - XRDP
  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "/run/current-system/sw/bin/cinnamon";
  networking.firewall.allowedTCPPorts = [ 3389 ];
}
