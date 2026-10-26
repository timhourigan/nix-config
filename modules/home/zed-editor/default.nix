{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.home.zed-editor;
  # Use the unstable version of zed
  unstable = true;
in
{
  options = {
    modules.home.zed-editor = {
      enable = lib.mkEnableOption "Zed" // {
        description = "Enable Zed Editor";
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.zed-editor = {
      enable = true;
      package = if unstable then pkgs.unstable.zed-editor else pkgs.zed-editor;
      # Let Nix manage `~/.config/zed/settings.json`
      mutableUserSettings = false;
      # Auto-installed by Zed on startup
      # Search with:
      # https://zed.dev/extensions
      extensions = [
        # Languages
        "make" # Makefile
        "nix" # Nix
        "terraform" # Terraform
        # Editor appearance
        "material-icon-theme"
        "dracula"
      ];
      # Language servers and formatters, available to Zed only
      # Use Nix packaged binaries, as those downloaded by Zed may not run on NixOS
      extraPackages = with pkgs; [
        # Nix
        nixd
        nixfmt
        # Python
        basedpyright
        ruff
        # Rust
        rust-analyzer
        # Terraform
        terraform-ls
        # YAML
        yaml-language-server
        # Runtime for Node based tools
        nodejs
      ];
      userSettings = {
        # Material Icons
        icon_theme = "Material Icon Theme";
        theme = {
          mode = "system";
          light = "One Light";
          dark = "Dracula";
        };
        # Match Alacritty font, sizes are in pixels (Alacritty's 12pt is ~16px)
        buffer_font_family = "FiraCode Nerd Font";
        buffer_font_size = 16;
        terminal = {
          font_family = "FiraCode Nerd Font";
          font_size = 16;
        };
        # Project panel on the left
        project_panel.dock = "left";
        # Claude Code agent
        agent_servers."Claude Code" = {
          type = "custom";
          command = lib.getExe pkgs.unstable.claude-agent-acp;
        };
        # Load project environments from `.envrc`
        load_direnv = "shell_hook";
        # Turn off telemetry
        telemetry = {
          diagnostics = false;
          metrics = false;
        };
        # Turn off auto-updates, let Nix manage
        auto_update = false;
        # Single final newline, strip trailing whitespace
        ensure_final_newline_on_save = true;
        remove_trailing_whitespace_on_save = true;
        # Format on save
        format_on_save = "on";
        languages = {
          # Python
          Python = {
            language_servers = [
              "basedpyright"
              "ruff"
            ];
            formatter.language_server.name = "ruff";
            # Organize imports on save
            code_actions_on_format."source.organizeImports.ruff" = true;
          };
          Nix = {
            # nixd only, nil duplicates diagnostics and completions
            language_servers = [ "nixd" ];
            formatter.external.command = "nixfmt";
          };
        };
      };
    };
  };
}
