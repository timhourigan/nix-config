{ config, lib, options, ... }:

let
  cfg = config.modules.home.rofi;
in
{
  options = {
    modules.home.rofi = {
      enable = lib.mkEnableOption "Rofi" // {
        description = "Enable Rofi";
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.rofi = {
      enable = true;
      font = "Droid Sans Mono 16";
      terminal = "${pkgs.alacritty}/bin/alacritty";
      theme = "gruvbox-dark-hard";
    };
  };
}
