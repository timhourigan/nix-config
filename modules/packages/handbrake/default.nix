{ config, lib, pkgs, ... }:

let
  cfg = config.modules.packages.handbrake;
in
{
  options = {
    modules.packages.handbrake = {
      enable = lib.mkEnableOption "handbrake" // {
        description = "Enable handbrake video transcoder package";
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      handbrake
    ];
  };
}
