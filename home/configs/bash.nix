{
  programs.bash = {
    enable = true;
    historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
    # Unlimited history
    historyFileSize = -1;
    historySize = -1;
    shellAliases = {
      diff = "diff --color=auto";
      l = "eza --long --group --git --all";
      c = "code .";
      docker = "podman";
      docker-compose = "podman-compose";
      # Switch this machine's Home-Manager config (from anywhere)
      home-switch = "home-manager switch --flake \"$HOME/code/nix-config#\$USER@\$(hostname)\" -b backup";
      hm = "home-switch";
    };
  };
}
