{ config, lib, ... }:

{
  # Match the distrobox container's custom home directory
  home.homeDirectory = lib.mkForce "/home/${config.home.username}/distrobox/amd64linux-t";

  # Ignore insecure completion directories (Nix store paths in distrobox)
  programs.zsh.completionInit = "autoload -U compinit && compinit -i";

  # Modules
  modules.home = {
    zsh.enable = true;
  };
}
