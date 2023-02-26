{ ... }:

{
  services = {
    polybar = {
      enable = true;
      script = ''polybar top &'';
      config = {
        "colors" = {
          fg = "#f2f2f2";
          bg = "#333333";
          orange = "#f99157";
        };

        "bar/top" = {
          bottom = false;
          offset-x = 5;
          offset-y = 5;
          radius = 2;
          padding = 2;
          # font-N = <fontconfig pattern>;<vertical offset>
          #  - Use fc-list for fontconfig information
          font-0 = "FiraCode Nerd Font:style=Bold:size=14;2";
          separator = " | ";
          modules-left = "filesystem memory cpu";
          modules-right = "time";
          background = "\${colors.bg}";
          foreground = "\${colors.fg}";
        };

        "module/time" = {
          type = "internal/date";
          date = "%a %d %b %Y";
          time = "%H:%M";
          label = "%{F#f99157}%{F-} %time% %{F#f99157}%{F-} %date% ";
        };

        "module/cpu" = {
          type = "internal/cpu";
          warn-percentage = 90;
          format-prefix = "CPU ";
          format-prefix-foreground = "\${colors.orange}";
          label = "%percentage%%";
          interval = "5";
        };

        "module/memory" = {
          type = "internal/memory";
          format-prefix = "RAM ";
          format-prefix-foreground = "\${colors.orange}";
          label = "%percentage_used%%";
          interval = "10";
        };

        "module/filesystem" = {
          type = "internal/fs";
          mount-0 = "/";
          label-mounted = "%{F#f99157}%mountpoint%%{F-} %percentage_used%%";
          interval = "60";
        };
      };
    };
  };
}
