{ pkgs, ... }:

{
  programs.rofi = {
    enable = true;
    font = "Droid Sans Mono 16";
    terminal = "${pkgs.alacritty}/bin/alacritty";
    theme = "gruvbox-dark-hard";
  };
}
