# Generate with `nixos-generate-config --show-hardware-config`
{ config, lib, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "usbhid" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/d318376a-381a-4e34-881c-b92037322da2";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/7FAB-6B82";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/d08ca87e-ef8d-4dee-9809-566aa3654024"; }];


  # fileSystems."/" =
  #   {
  #     device = "/dev/disk/by-label/os";
  #     fsType = "ext4";
  #   };

  # fileSystems."/boot/efi" =
  #   {
  #     device = "/dev/disk/by-label/boot";
  #     fsType = "vfat";
  #   };

  # swapDevices =
  #   [{ device = "/dev/disk/by-label/swap"; }];

  networking.useDHCP = lib.mkDefault true;
  # FIXME
  # networking.interfaces.enp0s31f6.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # FIXME

  #   hardware.graphics = {
  #     enable = true;
  #     extraPackages = with pkgs; [
  #       # Taken from https://wiki.nixos.org/wiki/Jellyfin and tailored for 11th gen,
  #       # with some guesswork.
  #       intel-media-driver # For Broadwell (2014) or newer processors. LIBVA_DRIVER_NAME=iHD
  #       # intel-vaapi-driver # For older processors. LIBVA_DRIVER_NAME=i965
  #       libva-vdpau-driver # Previously vaapiVdpau
  #       # intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
  #       # # OpenCL support for intel CPUs before 12th gen
  #       # # see: https://github.com/NixOS/nixpkgs/issues/356535
  #       intel-compute-runtime-legacy1
  #       vpl-gpu-rt # QSV on 11th gen or newer
  #       # intel-media-sdk # QSV up to 11th gen
  #       intel-ocl # OpenCL support
  #     ];
  #   };
}
