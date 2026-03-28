{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:

# https://wiki.nixos.org/wiki/Libvirt
# https://github.com/AshleyYakeley/NixVirt

# Assumes the following paths exist:
# - /var/lib/libvirt/images (for VM storage)
# - /var/lib/libvirt/isos (for ISO install media)

let
  cfg = config.modules.services.libvirt;
in
{
  imports = [
    inputs.NixVirt.nixosModules.default
  ];

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
      vms = lib.mkOption {
        description = "Declarative VM definitions managed by NixVirt";
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              uuid = lib.mkOption {
                description = "VM UUID (generate with `uuidgen`)";
                type = lib.types.str;
              };
              memory = lib.mkOption {
                description = "Memory allocation";
                type = lib.types.submodule {
                  options = {
                    count = lib.mkOption {
                      type = lib.types.int;
                      default = 2;
                    };
                    unit = lib.mkOption {
                      type = lib.types.str;
                      default = "GiB";
                    };
                  };
                };
                default = {
                  count = 2;
                  unit = "GiB";
                };
              };
              vcpu = lib.mkOption {
                description = "Number of virtual CPUs";
                type = lib.types.int;
                default = 2;
              };
              diskSize = lib.mkOption {
                description = "Disk size (e.g. 20)";
                type = lib.types.int;
                default = 20;
              };
              installMedia = lib.mkOption {
                description = "Path to ISO install media";
                type = lib.types.nullOr lib.types.str;
                default = null;
              };
            };
          }
        );
        default = { };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        swtpm.enable = true; # TPM emulation
      };
    };

    # virt-manager GUI
    programs.virt-manager.enable = true;

    # Add user to libvirtd group
    users.users.${cfg.user}.extraGroups = [ "libvirtd" ];

    # Packages
    environment.systemPackages = with pkgs; [
      spice-gtk # USB redirection & clipboard sharing
    ];

    # NixVirt declarative VM management
    virtualisation.libvirt = lib.mkIf (cfg.vms != { }) {
      enable = true;
      connections."qemu:///system" = {
        # Network - NAT bridge
        networks = [
          {
            definition = inputs.NixVirt.lib.network.writeXML (
              inputs.NixVirt.lib.network.templates.bridge {
                uuid = "a6be191e-1654-4f82-b5c0-87361de498ef"; # Generated with `uuidgen`
                subnet_byte = 122;
              }
            );
            active = true;
          }
        ];

        # Storage pool and volumes
        pools = [
          {
            definition = inputs.NixVirt.lib.pool.writeXML {
              name = "images";
              uuid = "f2b4e72c-9a1d-4c3f-8b7e-6d5a4c3b2a1e"; # Generated with `uuidgen`
              type = "dir";
              target = {
                path = "/var/lib/libvirt/images";
              };
            };
            active = true;
            volumes = lib.mapAttrsToList (name: vmCfg: {
              definition = inputs.NixVirt.lib.volume.writeXML {
                name = "${name}.qcow2";
                capacity = {
                  count = vmCfg.diskSize;
                  unit = "GB";
                };
                target = {
                  format = {
                    type = "qcow2";
                  };
                };
              };
            }) cfg.vms;
          }
        ];

        # Domain definitions
        domains = lib.mapAttrsToList (name: vmCfg: {
          definition = inputs.NixVirt.lib.domain.writeXML (
            inputs.NixVirt.lib.domain.templates.linux {
              inherit name;
              inherit (vmCfg) uuid;
              memory = {
                inherit (vmCfg.memory) count;
                inherit (vmCfg.memory) unit;
              };
              storage_vol = {
                pool = "images";
                volume = "${name}.qcow2";
              };
              install_vol = if vmCfg.installMedia != null then vmCfg.installMedia else null;
            }
          );
        }) cfg.vms;
      };
    };
  };
}
