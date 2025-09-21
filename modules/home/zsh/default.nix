{ config, lib, options, ... }:

let
  cfg = config.modules.home.zsh;
in
{
  options = {
    modules.home.zsh = {
      enable = lib.mkEnableOption "Zsh" // {
        description = "Enable Zsh";
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      history = {
        size = -1;
      };
      shellAliases = {
        diff = "diff --color=auto";
        l = "eza --long --group --git --all";
      };

      oh-my-zsh = {
        enable = true;
        plugins = [ "git" ];
        theme = "robbyrussell";
      };
    };
  };
}
