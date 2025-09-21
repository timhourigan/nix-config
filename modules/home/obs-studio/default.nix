{ config, lib, options, pkgs, ... }:

let
  cfg = config.modules.home.obs-studio;
in
{
  options = {
    modules.home.obs-studio = {
      enable = lib.mkEnableOption "OBS Studio" // {
        description = "Enable OBS Studio";
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        obs-pipewire-audio-capture
      ];
    };
  };
}
