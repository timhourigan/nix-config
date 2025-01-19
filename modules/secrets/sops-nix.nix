{ lib, config, options, inputs, ... }:

let
  cfg = config.modules.secrets.sops-nix;
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  options = {
    modules.secrets.sops-nix = {
      enable = lib.mkEnableOption "sops-nix" // {
        description = "Enable sops-nix secrets management";
        default = false;
      };
      defaultSopsFile = lib.mkOption {
        type = lib.types.path;
        default = ../../secrets/secrets.yaml;
        description = "Path to the default sops file";
      };
      defaultSopsFormat = lib.mkOption {
        type = lib.types.str;
        default = "yaml";
        description = "Default sops file format";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      defaultSopsFile = cfg.defaultSopsFile;
      defaultSopsFormat = cfg.defaultSopsFormat;
      age = {
        # Import host SSH keys as Age keys
        sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        # Specify the key file to use, generating it if not present
        keyFile = "/var/lib/sops-nix/key.txt";
        generateKey = true;
      };
    };
  };
}
