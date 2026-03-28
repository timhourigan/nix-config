{ lib, config, ... }:

let
  cfg = config.modules.services.ssh;
in
{
  options = {
    modules.services.ssh = {
      enable = lib.mkEnableOption "ssh access" // {
        description = "Enable ssh access";
        default = false;
      };
      passwordAuthentication = lib.mkOption {
        description = "Enable password authentication";
        type = lib.types.bool;
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = cfg.passwordAuthentication;
        KbdInteractiveAuthentication = cfg.passwordAuthentication;
      };
    };
  };
}
