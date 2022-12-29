{
  programs.bash = {
    enable = true;
    historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
    # Unlimited history
    historyFileSize = -1;
    historySize = -1;
    shellAliases = {
      diff = "diff --color=auto";
      l = "exa --long --group --git --all";
    };
  };
}

