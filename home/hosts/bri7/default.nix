{ pkgs, ... }:

{
  # Packages to be installed
  home.packages = with pkgs; [
    # Apps
    audacity # Audio editor
    avidemux # Video editor
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
