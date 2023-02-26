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
