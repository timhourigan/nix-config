{ lib, config, options, ... }:

let
  cfg = config.modules.desktops.xfce;
in
{
  options = {
    modules.desktops.xfce = {
      enable = lib.mkEnableOption "xfce" // {
        description = "Enable XFCE desktop";
        default = false;
      };
      enableRDP = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable remote desktop";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable XFCE desktop in X11
    services.xserver = {
      enable = true;
      displayManager.lightdm.enable = true;
      desktopManager.xfce.enable = true;
      xkb = {
        layout = "ie";
        variant = "";
      };
    };

    # Enable remote desktop
    services.xrdp = {
      enable = cfg.enableRDP;
      defaultWindowManager = if cfg.enableRDP then "/run/current-system/sw/bin/xfce4-session" else null;
    };
    networking.firewall.allowedTCPPorts = if cfg.enableRDP then [ 3389 ] else [ ];
  };
}
