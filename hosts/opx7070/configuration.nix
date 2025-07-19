{ config, outputs, pkgs, ... }:

{
  imports = [
    ../../modules
    ../common
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

  # Allow packages to be pushed from other systems e.g.
  # nixos-rebuild build --target-host <hostname> --flake .
  nix.settings.trusted-users = [ "timh" ];

  # Bootloader
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  # Filesystem support
  boot = {
    supportedFilesystems = [ "ntfs" "zfs" ];
    zfs.forceImportRoot = false; # Recommended setting
  };
  services.zfs.autoScrub = {
    enable = true;
    interval = "*-*-1,15 04:00:00"; # 1st and 15th of every month at 4am
  };

  # Networking
  networking = {
    hostName = "opx7070";
    networkmanager.enable = true;
    # Required for ZFS
    hostId = "6b3f7344"; # `head -c4 /dev/urandom | od -A none -t x4`
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
    desktops.xfce.enable = true;
    secrets.sops-nix.enable = true;
    services = {
      avahi.enable = true;
      chrony =
        {
          enable = true;
          # Enable server functionality and allow access from local network
          extraConfig = "allow 192.168.0.0/16";
        };
      gatus = {
        enable = true;
        openFirewall = true;
        package = pkgs.unstable.gatus;
        configFile = config.sops.secrets."gatus".path;
      };
      gc.enable = true;
      glances.enable = true;
      hass = {
        enable = true;
        extraOptions = [
          "--network=host"
          "--dns=9.9.9.9" # WORKAROUND - HA can start before DNS is up on boot
        ];
        # https://github.com/home-assistant/core/releases
        image = "ghcr.io/home-assistant/home-assistant:2025.7.2";
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/zi/zigbee2mqtt/package.nix
        z2mPackage = pkgs.unstable.zigbee2mqtt_1;
      };
      podman = {
        enable = true;
        autoPrune = true;
      };
      slimserver = {
        enable = true;
        package = pkgs.unstable.slimserver;
      };
      ssh.enable = true;
      tailscale =
        {
          enable = true;
          enableDNS = false;
        };
    };
    system.autoUpgrade = {
      enable = true;
      dates = "04:00";
      flake = "github:timhourigan/nix-config";
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
