{ config, outputs, pkgs, lib, ... }:

{
  imports = [
    ../../modules
    ../common/desktop-xfce.nix
    ../common/localisation.nix
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
      # Pi-Hole DNS with Unbound
      pihole = {
        enable = true;
        extraOptions = [
          "--network=host"
        ];
        # FIXME
        # extraOptions = [
        #   "--cap-add=NET_BIND_SERVICE"
        # ];
        # Use Unbound, accessing via internal Podman interface
        environment.FTLCONF_dns_upstreams = "127.0.0.1#5335";
        # FIXME
        # environment.FTLCONF_dns_upstreams = "10.88.0.1#5335";
        environmentFiles = [ config.sops.secrets."pihole_env".path ];
        # environment.FTLCONF_webserver_api_password = "use-to-set-initial-password";
        image = "docker.io/pihole/pihole:2025.04.0";
      };
      unbound = {
        enable = true;
        # FIXME
        # Allow access from Podman/Pi-Hole
        # settings.server.interface = [ "10.88.0.1" ];
        # settings.server.access-control = [ "10.88.0.0/16 allow" ];
      };
      # Podman virtualisation
      podman.enable = true;
      # SSH server
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
