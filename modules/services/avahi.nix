{ lib, config, options, ... }:

# https://mynixos.com/options/services.avahi

let
  cfg = config.modules.services.avahi;
in
{
  options = {
    modules.services.avahi = {
      enable = lib.mkEnableOption "Avahi service discovery" // {
        description = "Enable Avahi service discovery";
        default = false;
      };
      nssmdns4 = lib.mkOption {
        description = "Enable mDNS NSS (Name Service Switch) module for IPv4";
        type = lib.types.bool;
        default = true;
      };
      enablePublish = lib.mkOption {
        description = "Enable Avahi publishing";
        type = lib.types.bool;
        default = true;
      };
      enablePublishAddresses = lib.mkOption {
        description = "Enable Avahi publishing of addresses";
        type = lib.types.bool;
        default = true;
      };
      enablePublishDomain = lib.mkOption {
        description = "Enable Avahi publishing of domain";
        type = lib.types.bool;
        default = true;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.avahi = {
      enable = true;
        nssmdns4 = cfg.nssmdns4;
        publish = {
            enable = cfg.enablePublish;
            addresses = cfg.enablePublishAddresses;
            domain = cfg.enablePublishDomain;
        };
    };
  };
}
