{ config, pkgs, ... }:

{
  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Home Manager release
  home.stateVersion = "22.05";

  # User info
  home.username = "timh";
  home.homeDirectory = "/home/timh";

  # Allow fontconfig to discover installed fonts and configurations
  fonts.fontconfig.enable = true;

  # Packages to be installed
  home.packages = with pkgs; [
    # Utils
    bat # `cat` clone
    bottom # Display process information (`top` alternative)
    du-dust # Disk space usage (`du` alternative)
    exa # File listing (`ls` alternative)
    fd # Find files/folders (`find` alternative)
    feh # Command line image viewer
    gitleaks # Git repository secrets checker
    htop # Display process information (`top` alternative)
    jq # Command line JSON parser
    neofetch # System information
    nixfmt # NIX formatter
    nmap # Network exploration
    ripgrep # Fast grep
    taskwarrior # Task manager
    tig # git text-mode interface
    tldr # Help pages
    tree # Display directory struture

    # Apps
    filezilla # FTP client
    gimp # Image editor
    libreoffice # Office suite
    meld # Diff tools
    vlc # Media player

    # Browsers
    chromium

    # Fonts
    (nerdfonts.override {
      fonts = [
        "DejaVuSansMono"
        "DroidSansMono"
        "FiraCode"
        "Hack"
        "JetBrainsMono"
        "LiberationMono"
        "Terminus"
      ];
    })
    twitter-color-emoji
    noto-fonts-emoji
    powerline-fonts

    # Node
    nodejs

    # Python
    (python310.withPackages (ps: with ps; [ black flake8 pip ]))
  ];

  # Programs and configurations to be installed
  imports = [
    ./configs/alacritty.nix
    ./configs/autojump.nix
    ./configs/bash.nix
    ./configs/dconf.nix
    ./configs/direnv.nix
    ./configs/firefox.nix
    ./configs/fzf.nix
    ./configs/gh.nix
    ./configs/git.nix
    ./configs/neovim.nix
    ./configs/polybar.nix
    ./configs/rofi.nix
    ./configs/starship.nix
    ./configs/tmux.nix
    ./configs/vscodium.nix
    # ./configs/zsh.nix
  ];

  systemd.user.services.polybar = {
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
