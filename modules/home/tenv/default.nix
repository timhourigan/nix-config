{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.home.tenv;
in
{
  options = {
    modules.home.tenv = {
      enable = lib.mkEnableOption "tenv" // {
        description = "Enable tenv";
        default = false;
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.tenv;
        description = "The tenv package to use";
      };

      autoInstall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Automatically install missing tool versions when detected";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.initExtra = lib.mkIf cfg.autoInstall ''
      export TENV_AUTO_INSTALL="true"
    '';

    programs.zsh.initContent = lib.mkIf cfg.autoInstall ''
      export TENV_AUTO_INSTALL="true"
    '';
  };
}
