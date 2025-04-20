{ config, outputs, pkgs, lib, ... }:

{
  imports = [
    ../../modules/services/avahi.nix
    ../../modules/services/gc.nix
    ../../modules/secrets/sops-nix.nix
    ../../modules/services/glances.nix
    ../../modules/services/ssh.nix
    ../common/users-groups.nix
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

  # Allow packages to be pushed from other systems e.g.
  # nixos-rebuild build --target-host <hostname> --flake .
  nix.settings.trusted-users = [ "timh" ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # Networking
  networking.hostName = "m625q";
  networking.networkmanager.enable = true;

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

  # Desktop - XFCE
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.xfce.enable = true;

  # Remote Desktop - Xrdp - Commented out for now
  # services.xrdp.enable = true;
  # services.xrdp.defaultWindowManager = "/run/current-system/sw/bin/xfce4-session";
  # networking.firewall.allowedTCPPorts = [ 3389 ];

  # System packages
  environment.systemPackages = with pkgs; [
    bash-completion
    git
    gnumake
    vim
    wget
  ];

  # Allow vscode code server to work
  programs.nix-ld.enable = true;

  # Modules
  modules = {
    secrets = {
      # sops-nix secrets management
      sops-nix.enable = true;
    };
    services = {
      # Avahi service discovery
      avahi.enable = true;
      # Garbage collection
      gc.enable = true;
      # Glances monitoring service
      glances.enable = true;
      # SSH server
      ssh.enable = true;
    };
  };

  # Secrets
  sops = {
    secrets = { };
  };

  # Release version of first install
  system.stateVersion = "22.05";
}
