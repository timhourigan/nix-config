{
  config,
  lib,
  pkgs,
  ...
}:

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
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      historySubstringSearch.enable = true;
      plugins = [
        {
          name = "zsh-completions";
          src = pkgs.zsh-completions;
        }
      ];
      history = {
        size = 100000; # Keep a large but bounded history
        save = 100000;
        ignoreDups = true;
        ignoreAllDups = true;
        ignoreSpace = true;
        extended = true; # Save timestamps
        share = true; # Share history between sessions
      };
      shellAliases = {
        diff = "diff --color=auto";
        l = "eza --long --group --git --all";
      };
      sessionVariables = {
        LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib";
        PATH = "$PATH:$HOME/.local/bin";
      };
      initContent = lib.mkBefore ''
        # Re-prepend Nix paths after macOS path_helper reorders PATH in login shells
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
          PATH="''${HOME}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:''${PATH}"
        fi

        # Auto-cd into directories by typing the directory name
        setopt AUTO_CD
        # Extended globbing
        setopt EXTENDED_GLOB
        # Allow comments in interactive shell
        setopt INTERACTIVE_COMMENTS
      '';
    };
  };
}
