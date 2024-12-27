{ config, outputs, pkgs, ... }:

{
  # Packages to be installed
  home.packages = with pkgs; [
    # Apps
    # audacity # Audio editor
    # avidemux # Video editor
    # brasero # CD/DVD burner
    # devede # CD/DVD creator
    # freetube # Youtube client
    # filezilla # FTP client
    # gimp # Image editor
    # inkscape # SVG editor
    libreoffice # Office suite
    # meld # Diff tools
    # obsidian # Notes
    # remmina # Remove desktop client
    # subversion # Software version control
    # telegram-desktop # Messaging
    # vlc # Media player
    # zed-editor # Text editor
  ];
}
