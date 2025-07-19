# Generate with `nixos-generate-config --show-hardware-config`
{ config, lib, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  # Disable Wifi modules (lspci -nnk | grep -i BCM4360 -A3)
  boot.blacklistedKernelModules = [ "bcma" "wl" ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-label/os";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  fileSystems."/mnt/backup" =
    {
      device = "/dev/disk/by-label/backup";
      fsType = "ext4";
      options = [ "nofail" ]; # Allow system to boot without this device
    };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/a992f126-11d6-4ba1-a014-48150b148ebe"; }];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  # Don't want wireless
  # networking.useDHCP = lib.mkDefault true;
  networking.interfaces.enp3s0f0.useDHCP = lib.mkDefault true;
  networking.interfaces.wlp2s0.useDHCP = lib.mkDefault false;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
