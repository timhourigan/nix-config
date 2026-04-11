{ config, lib, ... }:

{
  # Match the distrobox container's custom home directory
  home.homeDirectory = lib.mkForce "/home/${config.home.username}/distrobox/amd64linux-t";

  # Skip compinit insecure directory check (Nix store paths in distrobox)
  programs.zsh.completionInit = "autoload -U compinit && compinit -u";

  # Modules
  modules.home = {
    zsh.enable = true;
  };
}
