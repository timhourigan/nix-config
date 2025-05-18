{ lib, config, options, ... }:

# https://jellyfin.org
# https://wiki.nixos.org/wiki/Jellyfin
# https://search.nixos.org/options?query=jellyfin

let
  cfg = config.modules.services.jellyfin;
in
{
  options = {
    modules.services.jellyfin = {
      enable = lib.mkEnableOption "jellyfin" // {
        description = "Enable jellyfin";
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.jellyfin = {
      enable = true;
      openFirewall = true;
    };
  };
}
