{ lib, config, ... }:

# DisplayLink - https://nixos.wiki/wiki/Displaylink
# External Monitors
# Requires:
#  - (Sept 2025) `nix-prefetch-url --name displaylink-620.zip https://www.synaptics.com/sites/default/files/exe_files/2025-09/DisplayLink%20USB%20Graphics%20Software%20for%20Ubuntu6.2-EXE.zip`
#  OR
#  - Download latest to $PWD: https://www.synaptics.com/products/displaylink-graphics/downloads/ubuntu-6.2
#  - mv $PWD/"DisplayLink USB Graphics Software for Ubuntu6.2-EXE.zip" $PWD/displaylink-620.zip
#  - nix-prefetch-url file://$PWD/displaylink-620.zip
#

let
  cfg = config.modules.services.displaylink;
in
{
  options = {
    modules.services.displaylink = {
      enable = lib.mkEnableOption "DisplayLink USB Graphics" // {
        description = "Enable support for DisplayLink USB Graphics devices";
        default = false;
      };
      driver = lib.mkOption {
        description = "The X11 driver to use for DisplayLink devices";
        type = lib.types.str;
        default = "displaylink";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ cfg.driver ];
    services.xserver.videoDrivers = [ cfg.driver "modesetting" ];
  };
}
