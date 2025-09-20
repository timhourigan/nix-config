{ pkgs, ... }:

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
    mqtt-explorer # MQTT client/explorer
    telegram-desktop # Messaging
    # FIXME - Removing for now as it causes a compilation,
    # which fails in GitHub Actions, due to time and space
    # zed-editor # Text editor
  ];

  # Programs and configurations to be installed
  imports = [
    ../modules/home
    ./configs/abcde.nix
    ./configs/obs.nix
  ];

  # Modules
  modules = {
    home.vscode.enable = true;
  };
}
