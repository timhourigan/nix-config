{ ... }:

{
  # Remote Desktop - XRDP
  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "/run/current-system/sw/bin/xfce4-session";
  networking.firewall.allowedTCPPorts = [ 3389 ];
}
