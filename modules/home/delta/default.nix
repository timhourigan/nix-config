{ config, lib, ... }:

let
  cfg = config.modules.home.delta;
in
{
  options = {
    modules.home.delta = {
      enable = lib.mkEnableOption "delta" // {
        description = "Enable delta";
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        side-by-side = true;
        # delta --show-syntax-themes --dark
        syntax-theme = "Coldark-Dark";
      };
    };
  };
}
