{ config, lib, options, ... }:

let
  cfg = config.modules.home.fzf;
in
{
  options = {
    modules.home.fzf = {
      enable = lib.mkEnableOption "fzf" // {
        description = "Enable fzf";
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.fzf = {
      enable = true;
      enableBashIntegration = true;
      tmux = {
        enableShellIntegration = true;
      };
    };
  };
}
