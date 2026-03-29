{
  lib,
  config,
  pkgs,
  ...
}:

# https://wiki.nixos.org/wiki/Libvirt

let
  cfg = config.modules.services.libvirt;
in
{
  options = {
    modules.services.libvirt = {
      enable = lib.mkEnableOption "libvirt" // {
        description = "Enable libvirt virtualisation (QEMU/KVM)";
        default = false;
      };
      user = lib.mkOption {
        description = "User to add to the libvirtd group";
        type = lib.types.str;
        default = config.custom.defaultUser;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.hasAttr cfg.user config.users.users;
      enableGuiClient = lib.mkEnableOption "libvirt GUI / client tools (virt-manager, spice-gtk)";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          swtpm.enable = true; # TPM emulation
        };
      };

      # Add user to libvirtd group
      users.users.${cfg.user}.extraGroups = [ "libvirtd" ];
    })

    (lib.mkIf (cfg.enable && cfg.enableGuiClient) {
      # virt-manager GUI
      programs.virt-manager.enable = true;

      # GUI-related packages
      environment.systemPackages = with pkgs; [
        spice-gtk # USB redirection & clipboard sharing
      ];
    })
  ];
}
