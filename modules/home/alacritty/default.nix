{ config, lib, ... }:

let
  cfg = config.modules.home.alacritty;
in
{
  options = {
    modules.home.alacritty = {
      enable = lib.mkEnableOption "Alacritty" // {
        description = "Enable Alacritty";
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      settings = {
        env.TERM = "xterm-256color";
        window = {
          decorations = "full";
          padding = {
            x = 4;
            y = 4;
          };
          startup_mode = "Maximized";
        };

        scrolling = {
          history = 100000;
          multiplier = 3;
        };

        mouse = {
          hide_when_typing = true;
        };
        cursor.style = "Underline";

        # Shift+Enter sends ESC + carriage return (\u001b\r)
        keyboard.bindings = [
          {
            key = "Return";
            mods = "Shift";
            chars = "\\u001b\\r";
          }
        ];

        font =
          let
            fontname = "FiraCode Nerd Font";
          in
          {
            normal = {
              family = fontname;
              style = "Medium";
            };
            bold = {
              family = fontname;
              style = "Bold";
            };
            italic = {
              family = fontname;
              style = "Light";
            };
            size = 12;
          };
      };
    };
  };
}
