{ config, outputs, ... }:

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

  # Bootloader
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  # Filesystem support
  boot.supportedFilesystems = [
    "ntfs"
    "zfs"
  ];
  boot.zfs.forceImportRoot = false; # Recommended setting
  services.zfs.autoScrub = {
    enable = true;
    interval = "*-*-1,15 04:00:00"; # 1st and 15th of every month at 4am
  };

  # Networking
  networking = {
    hostName = "sid";
    networkmanager.enable = true;
    # Required for ZFS
    hostId = "eef01409"; # `head -c4 /dev/urandom | od -A none -t x4`
  };

  # Run unpatched dynamic binaries
  programs.nix-ld.enable = true;

  # Modules
  modules = {
    desktops.xfce.enable = true;
    secrets.sops-nix.enable = true;
    services = {
      avahi.enable = true;
      forgejo = {
        enable = true;
        openFirewall = true;
        stateDir = "/mnt/zpool/forgejo";
        database.type = "sqlite";
        database.passwordFile = "${config.sops.secrets."forgejo/password_db".path}";
        dump.enable = true;
        domain = "forgejo.${config.custom.internalDomain}";
        settings.server.ROOT_URL = "http://forgejo.${config.custom.internalDomain}/";
      };
      glances.enable = true;
      ssh.enable = true;
    };
    system = {
      autoUpgrade = {
        enable = true;
        flake = "github:timhourigan/nix-config";
      };
      gc.enable = true;
      optimise.enable = true;
    };

  };

  # Secrets
  sops = {
    secrets = {
      "forgejo/password_db" = {
        owner = "forgejo";
      };
    };
  };

  # Reverse Proxy
  networking.firewall.allowedTCPPorts = [ 80 ];
  services.caddy = {
    enable = true;
    virtualHosts = {
      "http://forgejo.${config.custom.internalDomain}" = {
        extraConfig = ''
          reverse_proxy :3000
        '';
      };
    };
  };

  # Release version of first install
  system.stateVersion = "24.11";
}
