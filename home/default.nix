{
  inputs,
  outputs,
  ...
}:

{
  imports = [
    ../modules/home
    ./packages.nix
    # NUR modules
    inputs.nur.modules.homeManager.default
  ];

  nixpkgs = {
    overlays = [
      # Allow unstable packages at unstable.<package>
      outputs.overlays.unstable-packages
      # Allow pinned packages at pinned.<package>
      outputs.overlays.pinned-packages
    ];
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "ventoy-1.1.10" # https://github.com/ventoy/Ventoy/issues/3224
      ];
    };
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  home = {
    # Home Manager release
    stateVersion = "23.05";
    # User info
    username = "timh";
    homeDirectory = "/home/timh";
  };

  # Allow fontconfig to discover installed fonts and configurations
  fonts.fontconfig.enable = true;

  # Modules
  modules.home = {
    alacritty.enable = true;
    autojump.enable = true;
    bash.enable = true;
    delta.enable = true;
    direnv.enable = true;
    firefox.enable = true;
    fzf.enable = true;
    gh.enable = true;
    git.enable = true;
    neovim.enable = true;
    starship.enable = true;
    tmux.enable = true;
  };
}
