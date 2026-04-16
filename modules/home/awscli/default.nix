{ config, lib, ... }:

let
  cfg = config.modules.home.awscli;
in
{
  options = {
    modules.home.awscli = {
      enable = lib.mkEnableOption "awscli" // {
        description = "Enable AWS CLI";
        default = false;
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.awscli;
        description = "The awscli package to use";
      };

      settings = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Settings to add to the AWS CLI configuration file";
        example = {
          "default" = {
            region = "us-east-1";
            output = "json";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.awscli = {
      enable = true;
      inherit (cfg) package settings;
    };
  };
}
