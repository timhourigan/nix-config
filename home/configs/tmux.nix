{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    clock24 = true;
    historyLimit = 50000;
    mouse = true;
    newSession = true;
    prefix = "C-a";
    shell = "${pkgs.bashInteractive}/bin/bash";
    terminal = "screen-256color";
    baseIndex = 1;

    extraConfig = ''
      ##########
      # Mappings
      ##########

      # Remap split window commands
      bind | split-window -h
      bind - split-window -v
      unbind '"'
      unbind %

      # Map colon to command prompt
      bind : command-prompt

      # Map shift and left/right for window selection
      # No escape sequence needed, due to `-n`
      bind -n S-Left  previous-window
      bind -n S-Right next-window

      # Map shift down for new window - Disabled
      # No escape sequence needed, due to `-n`
      # bind -n S-down new-window

      # Map shift+meta/alt and direction for pane selection
      # No escape sequence needed, due to `-n`
      bind -n S-M-Left select-pane -L
      bind -n S-M-Right select-pane -R
      bind -n S-M-Up select-pane -U
      bind -n S-M-Down select-pane -D

      ###########
      # Behaviour
      ###########

      # Prevent automatic windows renaming
      set-option -g allow-rename off

      ############
      # Appearance
      ############

      # Set status bar colours
      set-option -g status-style bg=colour235,fg=yellow,dim

      # Set status bar refresh to every 15 seconds
      set -g status-interval 15

      # Set right status to `Day Date Time` - Disabled
      # set -g status-right " #[fg=colour255,bg=default]%a %d/%m %H:%M"

      # Set window title colours
      set-window-option -g window-status-style fg=colour247,bg=default,dim

      # Set active window title colours
      set-window-option -g window-status-current-style fg=colour255,bg=colour236,bright
    '';

    plugins = with pkgs; [
      {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15' # minutes
        '';
      }
      tmuxPlugins.resurrect
    ];
  };
}
