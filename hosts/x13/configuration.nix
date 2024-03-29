{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Use `nixos-options` to see configuration options e.g. `nixos-options service.<service-name>`

  # Feature onfiguration
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

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
  networking.hostName = "x13";
  networking.networkmanager.enable = true;

  # Localisation
  time.timeZone = "Europe/Dublin";
  i18n.defaultLocale = "en_IE.utf8";

  # X11
  services.xserver = {
    enable = true;
    layout = "ie";
    xkbVariant = "";
  };

  # Desktop - Cinnamon
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.cinnamon.enable = true;

  # DisplayLink - https://nixos.wiki/wiki/Displaylink
  # External Monitors
  # Requires:
  #  - (Feb 2024) `nix-prefetch-url --name displaylink-580.zip https://www.synaptics.com/sites/default/files/exe_files/2023-08/DisplayLink%20USB%20Graphics%20Software%20for%20Ubuntu5.8-EXE.zip`
  #  OR
  #  - Download latest to $PWD: https://www.synaptics.com/products/displaylink-graphics/downloads/ubuntu-5.8
  #  - mv $PWD/"DisplayLink USB Graphics Software for Ubuntu5.8-EXE.zip" $PWD/displaylink-580.zip
  #  - nix-prefetch-url file://$PWD/displaylink-580.zip
  #
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "displaylink" ];
  services.xserver.videoDrivers = [ "displaylink" "modesetting" ];

  # Printing
  services.printing.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns = true;
  # For WiFi printers
  services.avahi.openFirewall = true;

  # Scaanners
  # SANE support
  hardware.sane.enable = true;

  # Sound via Pipewire
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Power management
  # tlp - https://linrunner.de/tlp/settings
  services.tlp = {
    enable = true;
    settings = {
      # CPU
      # See options with `sudo tlp-stat -p`
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      # Battery
      # Start charging at 75%, stop charging at 85%
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 85;
      RESTORE_THRESHOLDS_ON_BAT = 1;
      # Platform
      # See options with `sudo tlp-stat -p`
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";
    };
  };
  # Thermald (Intel only) - https://wiki.debian.org/thermald
  # To be investigated if any benefit - Doesn't currently work due
  # to lap detection, which can be ignored with `--ignore-cpuid-check`
  # services.thermald = {
  #   enable = true;
  # };

  users.users.timh = {
    isNormalUser = true;
    description = "timh";
    # "scanner" for scanners
    # "lp" for printer/scanners
    extraGroups = [ "networkmanager" "wheel" "scanner" "lp" ];
    packages = with pkgs; [ firefox git bottom ];
    shell = pkgs.bash;
  };

  # FIXME - zsh
  # Enable zsh system wide
  # programs.zsh.enable = true;
  # Include zsh in /etc/shells
  # environment.shells = with pkgs; [ zsh ];

  # System packages
  environment.systemPackages = with pkgs; [
    bash-completion
    gnumake
    vim
    wget
  ];

  # Release version of first install
  system.stateVersion = "22.05";
}
