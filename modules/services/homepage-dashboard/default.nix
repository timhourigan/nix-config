{ lib, config, options, ... }:

# Homepage Dashboard
# https://gethomepage.dev
# https://mynixos.com/nixpkgs/options/services.homepage-dashboard

let
  cfg = config.modules.services.homepage-dashboard;
in
{
  options = {
    modules.services.homepage-dashboard = {
      enable = lib.mkEnableOption "Homepage Dashboard" // {
        description = "Enable the Homegage Dashboard";
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.homepage-dashboard = {
      enable = true;
    };
  };
}
