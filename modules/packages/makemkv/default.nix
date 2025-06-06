{ config, lib, options, pkgs, ... }:

let
  cfg = config.modules.packages.makemkv;
in
{
  options = {
    modules.packages.makemkv = {
      enable = lib.mkEnableOption "makemkv" // {
        description = "Enable makemkv ripper package";
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      makemkv
    ];

    # Needed for makemkv to access the DVD drive
    boot.kernelModules = [ "sg" ];
  };
}
