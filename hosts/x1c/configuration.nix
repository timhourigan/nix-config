{ config, outputs, pkgs, ... }:

{
  imports = [
    ../../modules
    ../common
    ./hardware-configuration.nix
  ];

  nixpkgs = {
    overlays = [
      # Allow unstable packages at unstable.<package>
      outputs.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
    };
  };

  # Use `nixos-option` to see configuration options e.g. `nixos-option service.<service-name>`

  # Feature configuration
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };
  };

  # Filesystem support
  boot.supportedFilesystems = [ "ntfs" ];

  # Networking
  networking.hostName = "x1c";
  networking.networkmanager.enable = true;

  # Printing
  services = {
    printing.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
      # For WiFi printers
      openFirewall = true;
    };
  };

  # Scanners
  # SANE support
  hardware.sane.enable = true;

  # Sound via Pipewire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Android
  programs.adb.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    bash-completion
    git
    gnumake
    vim
    wget
  ];

  # Modules
  modules = {
    desktops.cinnamon.enable = true;
    packages.abcde.enable = true;
    services = {
      avahi.enable = true;
      displaylink.enable = true;
      gc.enable = true;
      glances.enable = true;
      tlp.enable = true;
    };
  };

  # zram swap / RAM disk
  zramSwap.enable = true;

  # Release version of first install
  system.stateVersion = "22.05";
}
