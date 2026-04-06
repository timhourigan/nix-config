{ config, lib, ... }:

{
  # macOS home directory
  home.homeDirectory = lib.mkForce "/Users/${config.home.username}";
}
