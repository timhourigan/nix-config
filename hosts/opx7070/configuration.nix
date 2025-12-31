{ config, outputs, pkgs, ... }:

let
  gatusPort = 8080; # Module default
  hassPort = 8123; # Module default
  homepageDashboard = import ../common/homepage-dashboard.nix { };
  homepageDashboardPort = 8082;
  vikunjaPort = 3456; # Module default
  z2mPort = 8124; # Module default
in
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
      # Allow pinned packages at pinned.<package>
      outputs.overlays.pinned-packages
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
      freshrss = {
        enable = true;
        authType = "form";
        inherit (config.custom) defaultUser;
        extensions = with pkgs.unstable.freshrss-extensions; [
          reading-time
          title-wrap
          youtube
        ];
        passwordFile = config.sops.secrets."freshrss/password".path;
        webserver = "caddy";
        # TODO - Remove `http://` from virtualHost when certs are setup
        virtualHost = "http://freshrss.${config.custom.internalDomain}";
        baseUrl = "http://freshrss.${config.custom.internalDomain}";
      };
      gatus = {
        enable = true;
        openFirewall = true;
        package = pkgs.unstable.gatus;
        configFile = config.sops.secrets."gatus".path;
      };
      glances.enable = true;
      hass = {
        enable = true;
        extraOptions = [
          "--network=host"
          "--dns=9.9.9.9" # WORKAROUND - HA can start before DNS is up on boot
        ];
        # https://github.com/home-assistant/core/releases
        image = "ghcr.io/home-assistant/home-assistant:2025.12.5";
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/zi/zigbee2mqtt/package.nix
        z2mPackage = pkgs.pinned.zigbee2mqtt;
      };
      homepage-dashboard = {
        enable = true;
        environmentFile = config.sops.secrets."homepage_env".path;
        listenPort = homepageDashboardPort;
        # See Reverse Proxy setup below
        allowedHosts = "${config.custom.internalDomain}";
        inherit (homepageDashboard) bookmarks;
        inherit (homepageDashboard) settings;
        inherit (homepageDashboard) services;
        inherit (homepageDashboard) widgets;
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
      vikunja = {
        enable = true;
      };
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
      "freshrss/password" = {
        owner = "freshrss";
      };
      gatus = { };
      homepage_env = { };
      "mqtt/valetudo/larry/password" = { };
      "mqtt/valetudo/harry/password" = { };
    };
  };

  # Reverse Proxy
  # TODO
  # - Add `443` When certs are setup
  # - Remove `http://` from virtualHosts when certs are setup
  networking.firewall.allowedTCPPorts = [ 80 ];
  services.caddy = {
    enable = true;
    virtualHosts =
      {
        # FreshRSS - Module has builtin configuration
        # Gatus
        "http://gatus.${config.custom.internalDomain}" = {
          extraConfig = ''
            reverse_proxy :${toString gatusPort}
          '';
        };
        # Home Assistant
        "http://ha.${config.custom.internalDomain}" = {
          extraConfig = ''
            reverse_proxy :${toString hassPort}
          '';
        };
        # Homepage
        "http://${config.custom.internalDomain}" = {
          extraConfig = ''
            reverse_proxy :${toString homepageDashboardPort}
          '';
        };
        # Vikunja
        "http://vikunja.${config.custom.internalDomain}" = {
          extraConfig = ''
            reverse_proxy :${toString vikunjaPort}
          '';
        };
        "http://kanban.${config.custom.internalDomain}" = {
          extraConfig = ''
            reverse_proxy :${toString vikunjaPort}
          '';
        };
        # zigbee2mqtt
        "http://z2m.${config.custom.internalDomain}" = {
          extraConfig = ''
            reverse_proxy :${toString z2mPort}
          '';
        };
      };
  };

  # Release version of first install
  system.stateVersion = "24.05";
}
