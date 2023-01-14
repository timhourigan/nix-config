{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    clock24 = true;
    historyLimit = 50000;
    newSession = true;
    prefix = "C-a";
    shell = "${pkgs.bash}/bin/bash";
    terminal = "screen-256color";
  };
}
