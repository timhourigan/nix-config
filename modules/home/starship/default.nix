{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.home.starship;

  # WORKAROUND - Starship (as of 1.26.0) has no rate-limit statusline module
  # (only claude_model/claude_context/claude_cost), so wrap its Claude Code
  # statusline output with 5-hour/7-day rate limit usage parsed from the same
  # JSON Claude Code sends on stdin.
  claudeCodeStatusline = pkgs.writeShellApplication {
    name = "starship-claude-code-statusline";
    runtimeInputs = [
      cfg.package
      pkgs.coreutils
      pkgs.jq
    ];
    text = ''
      # Claude Code sends session JSON on stdin; read it once so it can be reused below
      input="$(cat)"

      # Render the normal Starship statusline from that same JSON
      starship_output="$(printf '%s' "$input" | starship statusline claude-code)"

      # rate_limits is only present for Claude.ai Pro/Max subscribers, and only
      # after the first API response in a session - "// empty" handles absence.
      # resets_at is a Unix epoch and may be independently absent
      five_hour=$(jq -r '.rate_limits.five_hour.used_percentage // empty' <<<"$input")
      five_hour_resets_at=$(jq -r '.rate_limits.five_hour.resets_at // empty' <<<"$input")
      seven_day=$(jq -r '.rate_limits.seven_day.used_percentage // empty' <<<"$input")

      reset=$'\033[0m'

      # Colour thresholds matching the claude_context/claude_cost overrides above
      color_for() {
        local pct=''${1%.*}
        if (( pct >= 80 )); then
          printf '\033[1;31m' # bold red
        elif (( pct >= 60 )); then
          printf '\033[1;33m' # bold yellow
        else
          printf '\033[1;32m' # bold green
        fi
      }

      # Render "<label> N% (HH:MM)" for one window; resets_at is optional
      # (omit the clock time when not given, e.g. for 7-day)
      render_window() {
        local label=$1 pct=$2 resets_at=$3
        local color pct_int resets
        color=$(color_for "$pct")
        pct_int=''${pct%.*}
        resets=""
        [[ -n "$resets_at" ]] && resets=" ($(date -d "@''${resets_at%.*}" "+%H:%M"))"
        printf '%s%s %s%%%s%s ' "$color" "$label" "$pct_int" "$resets" "$reset"
      }

      # Build the rate-limit segment, skipping windows that aren't present
      segment=""
      [[ -n "$five_hour" ]] && segment+="$(render_window "5h" "$five_hour" "$five_hour_resets_at")"
      [[ -n "$seven_day" ]] && segment+="$(render_window "7d" "$seven_day" "")"

      # Append the rate-limit segment after Starship's own output
      printf '%s%s\n' "$starship_output" "$segment"
    '';
  };
in
{
  options = {
    modules.home.starship = {
      enable = lib.mkEnableOption "Starship" // {
        description = "Enable Starship";
        default = false;
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.starship;
        description = "The starship package to use";
      };
      claudeCodeStatusLineCommand = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        description = ''
          Command for Claude Code's `statusLine.command` setting.
          Wraps `starship statusline claude-code` with 5-hour/7-day rate limit usage.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    modules.home.starship.claudeCodeStatusLineCommand = "${claudeCodeStatusline}/bin/starship-claude-code-statusline";

    programs.starship = {
      enable = true;
      inherit (cfg) package;
      enableBashIntegration = true;
      enableZshIntegration = true;
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
          display = [ { threshold = 20; } ];
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

        # Claude Code
        profiles."claude-code" =
          "$battery$time$directory$git_branch$git_status$memory_usage$claude_model$claude_context$claude_cost";

        claude_context = {
          format = "[$gauge $percentage]($style) ";
          display = [
            {
              threshold = 0;
              style = "bold green";
            }
            {
              threshold = 60;
              style = "bold yellow";
            }
            {
              threshold = 80;
              style = "bold red";
            }
          ];
        };

        claude_model.symbol = "";

        claude_cost = {
          symbol = "";
          display = [
            {
              threshold = 0;
              style = "bold green";
            }
            {
              threshold = 1;
              style = "bold yellow";
            }
            {
              threshold = 5;
              style = "bold red";
            }
          ];
        };
      };
    };
  };
}
