{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.home.pyenv;
in
{
  options = {
    modules.home.pyenv = {
      enable = lib.mkEnableOption "pyenv" // {
        description = "Enable pyenv";
        default = false;
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.pyenv;
        description = "The pyenv package to use";
      };

      rootDirectory = lib.mkOption {
        type = lib.types.path;
        default = "${config.xdg.dataHome}/pyenv";
        description = "The pyenv root directory (PYENV_ROOT)";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.pyenv = {
      enable = true;
      inherit (cfg) package rootDirectory;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
  };
}
