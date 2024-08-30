{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Use `nixos-options` to see configuration options e.g. `nixos-options service.<service-name>`

  # Feature configuration
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # FIXME boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # Filesystem support
  boot.supportedFilesystems = [ "ntfs" ];

  #   # Kernel pinning
  #   # Pinning to 5.15.97 as 5.15.99 doesn't boot completely
  #   # Now resolved, but leaving here for reference
  #   boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_5_15.override {
  #     argsOverride = rec {
  #       src = pkgs.fetchurl {
  #             url = "mirror://kernel/linux/kernel/v5.x/linux-${version}.tar.xz";
  #             # https://cdn.kernel.org/pub/linux/kernel/v5.x/sha256sums.asc
  #             sha256 = "2cddd6f4b1beaa2705b13022fb25a51f23f09faaa1a26cb859825f35080fb3b3";
  #       };
  #       version = "5.15.97";
  #       modDirVersion = "5.15.97";
  #       };
  #   });

  # Networking
  networking.hostName = "opx7070";
  networking.networkmanager.enable = true;
  services.tailscale.enable = true;

  # Localisation
  time.timeZone = "Europe/Dublin";
  i18n.defaultLocale = "en_IE.utf8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IE.UTF-8";
    LC_IDENTIFICATION = "en_IE.UTF-8";
    LC_MEASUREMENT = "en_IE.UTF-8";
    LC_MONETARY = "en_IE.UTF-8";
    LC_NAME = "en_IE.UTF-8";
    LC_NUMERIC = "en_IE.UTF-8";
    LC_PAPER = "en_IE.UTF-8";
    LC_TELEPHONE = "en_IE.UTF-8";
    LC_TIME = "en_IE.UTF-8";
  };

  # Configure console keymap
  console.keyMap = "ie";

  # X11
  services.xserver = {
    enable = true;
    xkb = {
      layout = "ie";
      variant = "";
    };
  };

  # Desktop - Cinnamon
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.cinnamon.enable = true;

  users.users.timh = {
    isNormalUser = true;
    description = "timh";
    # Networking: "networkmanager"
    # sudo: "wheel"
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [ ];
    shell = pkgs.bash;
  };

  # System packages
  environment.systemPackages = with pkgs; [
    bash-completion
    gnumake
    vim
    wget
  ];

  # Services
  services.openssh.enable = true;

  # Release version of first install
  system.stateVersion = "24.05";
}
