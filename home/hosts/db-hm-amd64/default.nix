{ lib, ... }:

{
  # Match the distrobox container's custom home directory
  home.homeDirectory = lib.mkForce "/home/timh/distrobox/db-hm-amd64";
}
