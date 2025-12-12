{ lib, config, ... }:

let
  cfg = config.modules.desktops.cinnamon;
in
{
  options = {
    modules.desktops.cinnamon = {
      enable = lib.mkEnableOption "cinnamon" // {
        description = "Enable Cinnamon desktop";
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
    # Enable Cinnamon desktop in X11
    services.xserver = {
      enable = true;
      displayManager.lightdm.enable = true;
      desktopManager.cinnamon.enable = true;
      xkb = {
        layout = "ie";
        variant = "";
      };
    };

    # Enable remote desktop
    services.xrdp = {
      enable = cfg.enableRDP;
      defaultWindowManager = if cfg.enableRDP then "/run/current-system/sw/bin/cinnamon" else null;
    };
    networking.firewall.allowedTCPPorts = if cfg.enableRDP then [ 3389 ] else [ ];
  };
}
