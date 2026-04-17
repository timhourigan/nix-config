{
  config,
  lib,
  ...
}:

let
  cfg = config.modules.home.ssh;
in
{
  options = {
    modules.home.ssh = {
      enable = lib.mkEnableOption "ssh" // {
        description = "Enable SSH client configuration";
        default = false;
      };

      package = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = null;
        description = "The openssh package to use. Defaults to the system client.";
      };

      matchBlocks = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Per-host SSH configuration blocks";
        example = {
          "example" = {
            hostname = "example.com";
            user = "deploy";
            identityFile = "~/.ssh/example_ed25519";
          };
        };
      };

      includes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "File globs of ssh config files to include";
      };

      extraConfig = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Extra SSH configuration";
      };

      extraOptionOverrides = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Extra SSH options that take precedence over host-specific configuration";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      inherit (cfg)
        package
        matchBlocks
        includes
        extraConfig
        extraOptionOverrides
        ;
    };
  };
}
