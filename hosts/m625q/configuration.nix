{ config, outputs, pkgs, lib, ... }:

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
  # Don't want wireless
  networking.wireless.enable = false;
  # Backup DNS server / Quad9
  networking.nameservers = [ "9.9.9.9" ];

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
      gc.enable = true;
      glances.enable = true;
      pihole = {
        enable = true;
        extraOptions = [
          "--cap-add=NET_BIND_SERVICE" # Allow binding to ports below 1024
          "--dns=9.9.9.9" # Container DNS
        ];
        # Use Unbound, accessing via Podman interface
        environment.FTLCONF_dns_upstreams = "10.88.0.1#5335";
        # Needed when using container bridged mode
        environment.FTLCONF_dns_listeningMode = "all";
        environmentFiles = [ config.sops.secrets."pihole_env".path ];
        # environment.FTLCONF_webserver_api_password = "use-to-set-initial-password";
        image = "docker.io/pihole/pihole:2025.04.0";
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
