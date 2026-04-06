{ config, lib, ... }:

{
  # Match the distrobox container's custom home directory
  home.homeDirectory = lib.mkForce "/home/${config.home.username}/distrobox/amd64linux-t";
}
