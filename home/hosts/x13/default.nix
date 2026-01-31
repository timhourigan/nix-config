{ pkgs, ... }:

{
  # Packages to be installed
  home.packages = with pkgs; [
    # Apps
    audacity # Audio editor
    avidemux # Video editor
    brasero # CD/DVD burner
    devede # CD/DVD creator
    font-manager # Font management
    freetube # Youtube client
    gimp # Image editor
    inkscape # SVG editor
    libreoffice # Office suite
    mqtt-explorer # MQTT client/explorer
    telegram-desktop # Messaging
    scribus # Desktop publishing
    zed-editor # Text editor
  ];

  # Programs and configurations to be installed
  imports = [
    ../../../modules/home
    ../../configs/abcde.nix
  ];

  # Modules
  modules.home = {
    polybar.enable = true;
    rofi.enable = true;
    vscode.enable = true;
  };
}
