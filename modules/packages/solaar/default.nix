{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.packages.solaar;
in
{
  options = {
    modules.packages.solaar = {
      enable = lib.mkEnableOption "solaar" // {
        description = "Enable Solaar, a Linux device manager for Logitech devices";
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      solaar
    ];
    hardware.logitech.wireless.enable = true;
    hardware.logitech.wireless.enableGraphical = true;
  };
}
