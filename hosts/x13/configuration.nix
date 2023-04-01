{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Feature onfiguration
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

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

  # Printing via CUPS
  services.printing.enable = true;

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

  users.users.timh = {
    isNormalUser = true;
    description = "timh";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [ firefox git bottom ];
    shell = pkgs.bash;
  };

  # FIXME - zsh
  # Enable zsh system wide
  # programs.zsh.enable = true;
  # Include zsh in /etc/shells
  # environment.shells = with pkgs; [ zsh ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

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
