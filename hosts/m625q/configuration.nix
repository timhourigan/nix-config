{ config, outputs, ... }:

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

  # Networking
  networking = {
    hostName = "m625q";
    networkmanager.enable = true;
    # Don't want wireless
    wireless.enable = false;
    # Backup DNS server / Quad9
    nameservers = [ "9.9.9.9" ];
  };

  # Allow vscode code server to work
  programs.nix-ld.enable = true;

  # Modules
  modules = {
    desktops.xfce.enable = true;
    secrets.sops-nix.enable = true;
    services = {
      avahi.enable = true;
      glances.enable = true;
      pihole = {
        enable = true;
        extraOptions = [
          "--cap-add=NET_BIND_SERVICE" # Allow binding to ports below 1024
          "--dns=9.9.9.9" # Container DNS
        ];
        environment = {
          # Use Unbound, accessing via Podman interface
          FTLCONF_dns_upstreams = "10.88.0.1#5335";
          # Needed when using container bridged mode
          FTLCONF_dns_listeningMode = "all";
          # Allow sudo access to webserver API - Required on replicas for Nebula Sync
          FTLCONF_webserver_api_app_sudo = "true";
          # FTLCONF_webserver_api_password = "use-to-set-initial-password";
        };
        environmentFiles = [ config.sops.secrets."pihole_env".path ];
        image = "docker.io/pihole/pihole:2025.11.0";
      };
      unbound = {
        enable = true;
        # Allow access from Podman interface (PiHole)
        settings.server.interface = [ "10.88.0.1" ];
        settings.server.access-control = [ "10.88.0.0/16 allow" ];
      };
      podman = {
        enable = true;
        autoPrune = true;
      };
      ssh.enable = true;
    };
    system = {
      autoUpgrade = {
        enable = true;
        dates = "03:00";
        flake = "github:timhourigan/nix-config";
      };
      gc = {
        enable = true;
        options = "--delete-older-than 7d";
      };
      optimise = {
        enable = true;
        dates = [ "05:00" ];
      };
    };

  };

  # Secrets
  sops = {
    secrets = {
      pihole_env = { };
    };
  };

  # Release version of first install
  system.stateVersion = "22.05";
}
