{ config, lib, ... }:

let
  cfg = config.modules.home.ghostty;
in
{
  options = {
    modules.home.ghostty = {
      enable = lib.mkEnableOption "Ghostty" // {
        description = "Enable Ghostty";
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      settings = {
        # https://ghostty.org/docs/config/reference
        font-family = "FiraCode Nerd Font";
        font-style = "Medium";
        font-style-bold = "Bold";
        font-style-italic = "Light";
        font-size = 12;

        window-padding-x = 4;
        window-padding-y = 4;
        window-decoration = "auto";
        maximize = true;

        scrollback-limit = 100000;

        cursor-style = "underline";
        mouse-hide-while-typing = true;
      };
    };
  };
}
