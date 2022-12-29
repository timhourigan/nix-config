{
  programs.alacritty = {
    enable = true;
    settings = {
      env.TERM = "xterm-256color";
      window = {
        decorations = "full";
        padding = { x = 4; y = 4; };
         startup_mode = "Maximized";
      };

      scrolling = {
        history = 100000;
        multiplier = 3;
      };

      mouse = { hide_when_typing = true; };
      cursor.style = "Underline";

      font = let fontname = "DejaVu Sans Mono for Powerline"; in {
        normal = { family = fontname; style = "Medium"; };
        bold = { family = fontname; style = "Bold"; };
        italic = { family = fontname; style = "Light"; };
        size = 12;
      };
    };
  };
}
