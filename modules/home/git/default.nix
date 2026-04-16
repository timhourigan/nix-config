{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.home.git;
in
{
  options = {
    modules.home.git = {
      enable = lib.mkEnableOption "git" // {
        description = "Enable git";
        default = false;
      };
      credentialHelper = lib.mkOption {
        description = "Git credential helper";
        type = lib.types.str;
        default = "libsecret";
      };
      userName = lib.mkOption {
        description = "Git user name";
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      userEmail = lib.mkOption {
        description = "Git user email";
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      package = pkgs.gitFull;
      enable = true;
      settings =
        {
          alias = {
            ci = "commit";
            co = "checkout";
            br = "branch";
            st = "status";
            pub = "push origin -u";
          };
          credential = {
            helper = cfg.credentialHelper;
          };
        }
        // lib.optionalAttrs (cfg.userName != null && cfg.userEmail != null) {
          user = {
            name = cfg.userName;
            email = cfg.userEmail;
          };
        };
    };
  };
}
