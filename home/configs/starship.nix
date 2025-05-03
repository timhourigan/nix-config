{ ... }:

{
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    # https://starship.rs/config/
    settings = {
      add_newline = false;

      time = {
        disabled = false;
        style = "dimmed white";
        format = "[$time]($style) ";
        time_format = "%R";
      };

      battery = {
        disabled = false;
        format = "[$symbol$percentage]($style) ";
        full_symbol = "🔋";
        charging_symbol = "🔌";
        discharging_symbol = "🪫";
        display = [{ threshold = 20; }];
      };

      username = {
        disabled = false;
        show_always = true;
        format = "[$user ]($style)";
      };

      directory = {
        format = "[$path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        truncate_to_repo = true;
      };

      git_branch = {
        format = "[$branch]($style)";
      };

      git_status = {
        format = "[$all_status$ahead_behind ]($style)";
      };

      memory_usage = {
        disabled = false;
        threshold = 90;
        symbol = " ";
        style = "bold red";
        format = "[$ram]($style) ";
      };

      hostname = {
        disabled = false;
        ssh_only = false;
        ssh_symbol = "@";
        format = "[$ssh_symbol$hostname]($style) ";
      };

      cmd_duration = {
        min_time = 2000; # Milliseconds
        show_milliseconds = false;
        disabled = false;
      };
    };
  };
}
