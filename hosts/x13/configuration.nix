{ outputs, pkgs, ... }:

{
  imports = [
    ../../modules
    ../common
    ./hardware-configuration.nix
    ./settings.nix
    ./testing.nix
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

  # Filesystem support
  boot.supportedFilesystems = [ "ntfs" ];

  # QEMU user-mode emulation for cross-architecture containers
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.binfmt.preferStaticEmulators = true;

  # Allow X11 connections from the current user (for containers)
  systemd.user.services.xhost-local = {
    description = "Allow X11 connections for current user";
    after = [ "graphical-session-pre.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.xorg.xhost}/bin/xhost +si:localuser:%u";
      RemainAfterExit = true;
    };
  };

  # Zsh
  programs.zsh.enable = true;
  environment.shells = with pkgs; [ zsh ];
  users.users.timh.shell = pkgs.zsh;

  # Networking
  networking = {
    hostName = "x13";
    networkmanager.enable = true;
  };

  # Printing
  services = {
    printing.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
      # For WiFi printers
      openFirewall = true;
    };
  };

  # Scanners
  # SANE support
  hardware.sane.enable = true;

  # Sound via Pipewire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Android
  programs.adb.enable = true;

  # Thermald (Intel only) - https://wiki.debian.org/thermald
  # To be investigated if any benefit - Doesn't currently work due
  # to lap detection, which can be ignored with `--ignore-cpuid-check`
  # services.thermald = {
  #   enable = true;
  # };

  # Modules
  modules = {
    desktops.cinnamon.enable = true;
    packages = {
      abcde.enable = true;
      handbrake.enable = true;
      makemkv.enable = true;
    };
    secrets.sops-nix.enable = true;
    services = {
      avahi.enable = true;
      displaylink.enable = true;
      glances.enable = true;
      podman.enable = true;
      ssh.enable = true;
      tailscale = {
        enable = true;
        enableDNS = false;
      };
      tlp.enable = true;
    };
    system = {
      gc.enable = true;
      optimise = {
        enable = true;
        dates = [ "weekly" ];
      };
    };
  };

  # zram swap / RAM disk
  zramSwap.enable = true;

  # Secrets
  sops = {
    secrets = { };
  };

  # Release version of first install
  system.stateVersion = "22.05";
}
