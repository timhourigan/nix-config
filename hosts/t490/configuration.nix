{ outputs, ... }:

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
      efi = {
        canTouchEfiVariables = true;
        # FIXME Needed? - efiSysMountPoint = "/boot/efi";
      };
    };
  };

  # Filesystem support
  boot.supportedFilesystems = [ "ntfs" ];

  # Networking
  networking = {
    hostName = "t490";
    networkmanager.enable = true;
    # Add hosts to /etc/hosts
    extraHosts =
      ''
    '';
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
      glances.enable = true;
      ssh.enable = true;
      tailscale =
        {
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
  system.stateVersion = "25.11";
}
