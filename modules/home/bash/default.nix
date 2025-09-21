{ config, lib, options, pkgs, ... }:

let
  cfg = config.modules.home.bash;
in
{
  options = {
    modules.home.bash = {
      enable = lib.mkEnableOption "Bash" // {
        description = "Enable Bash";
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.bash = {
      enable = true;
      enableCompletion = true;
      shellOptions = [
        "autocd" # Auto change directory
        "checkwinsize" # Update LINES and COLUMNS from window size
        "extglob" # Extend globbing
        "histappend" # Append to history
        "globstar" # Extend globbing (**)
      ];
      historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
      # Unlimited history
      historyFileSize = -1;
      historySize = -1;
      shellAliases = {
        diff = "diff --color=auto";
        l = "eza --long --group --git --all";
      };
      sessionVariables = {
        LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib";
        PATH = "$PATH:$HOME/.local/bin";
      };
    };
  };
}
