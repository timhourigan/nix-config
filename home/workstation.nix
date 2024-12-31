{ config, outputs, pkgs, ... }:

# `workstation` hosts

{
  # Packages to be installed
  home.packages = with pkgs; [
    # Apps
    audacity # Audio editor
    avidemux # Video editor
    brasero # CD/DVD burner
    devede # CD/DVD creator
    freetube # Youtube client
    gimp # Image editor
    inkscape # SVG editor
    libreoffice # Office suite
    telegram-desktop # Messaging
    zed-editor # Text editor
  ];

  # Programs and configurations to be installed
  imports = [
    ./configs/abcde.nix
    ./configs/obs.nix
  ];
}
