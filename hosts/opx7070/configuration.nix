{ config, outputs, pkgs, lib, ... }:

{
  imports = [
    ../../modules/services/gc.nix
    ../../modules/secrets/sops-nix.nix
    ../../modules/services/chrony.nix
    ../../modules/services/gatus.nix
    ../../modules/services/glances.nix
    ../../modules/services/hass.nix
    ../../modules/services/podman.nix
    ../../modules/services/ssh.nix
    ./backups.nix
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
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Filesystem support
  boot.supportedFilesystems = [ "ntfs" ];

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

  # Remote Desktop - Xrdp - Commented out for now
  # services.xrdp.enable = true;
  # services.xrdp.defaultWindowManager = "/run/current-system/sw/bin/cinnamon";
  # networking.firewall.allowedTCPPorts = [ 3389 ];

  users.users.timh = {
    isNormalUser = true;
    description = "timh";
    # Networking: "networkmanager"
    # sudo: "wheel"
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [ ];
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOdPJVS2P6fNEMuIAuJqCMtqLU4LAI50SeoAF5GyCFFl"
    ];
  };

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
      # Chrony NTP client and server
      chrony =
        {
          enable = true;
          # Enable server functionality and allow access from local network
          extraConfig = "allow 192.168.0.0/16";
        };
      # Gatus
      gatus = {
        enable = true;
        openFirewall = true;
        package = pkgs.unstable.gatus;
        configFile = config.sops.secrets."gatus".path;
      };
      # Garbage collection
      gc.enable = true;
      # Glances monitoring service
      glances.enable = true;
      # Podman virtualisation
      podman.enable = true;
      # SSH server
      ssh.enable = true;
      # Home Assistant
      hass = {
        enable = true;
        extraOptions = [
          "--network=host"
        ];
        # https://github.com/home-assistant/core/releases
        image = "ghcr.io/home-assistant/home-assistant:2025.2.4";
      };
    };
  };

  # Secrets
  sops = {
    secrets = {
      gatus = { };
      "mqtt/valetudo/larry/password" = { };
      "mqtt/valetudo/harry/password" = { };
    };
  };

  # Release version of first install
  system.stateVersion = "24.05";
}
