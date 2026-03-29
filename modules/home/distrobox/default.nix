{ config, lib, ... }:

let
  cfg = config.modules.home.distrobox;
in
{
  options = {
    modules.home.distrobox = {
      enable = lib.mkEnableOption "Distrobox" // {
        description = "Enable Distrobox";
        default = false;
      };
      containers = lib.mkOption {
        description = "Distrobox container definitions (passed to programs.distrobox.containers)";
        type = lib.types.attrs;
        default = { };
      };
      enableSystemdUnit = lib.mkOption {
        # Only impacts/creates non-existent distroboxes
        description = "Enable systemd unit to create non-existent distroboxes on config change";
        type = lib.types.bool;
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.distrobox = {
      enable = true;
      inherit (cfg) containers;
      inherit (cfg) enableSystemdUnit;
    };
  };
}
