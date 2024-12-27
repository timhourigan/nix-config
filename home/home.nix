{ config, outputs, pkgs, ... }:

{
  nixpkgs = {
    overlays = [
      # Allow unstable packages at unstable.<package>
      outputs.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
    };
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Home Manager release
  home.stateVersion = "23.05";

  # User info
  home.username = "timh";
  home.homeDirectory = "/home/timh";

  # Allow fontconfig to discover installed fonts and configurations
  fonts.fontconfig.enable = true;

  # Packages to be installed
  home.packages = with pkgs; [
    # Tools
    appimage-run # Run AppImage files
    bat # `cat` clone
    bottom # Display process information (`top` alternative)
    ddrescue # dd, with extra functionality
    du-dust # Disk space usage (`du` alternative)
    eza # File listing (`ls` alternative)
    fastfetch # System information
    fd # Find files/folders (`find` alternative)
    feh # Command line image viewer
    ffmpeg-full # Audio video manipulation
    gitleaks # Git repository secrets checker
    gparted # Disk partition tool
    hdparm # Disk utility (set/get parameters, read-only speed test)
    htop # Display process information (`top` alternative)
    jq # Command line JSON parser
    mediainfo # Media file information
    nmap # Network exploration
    nvd # Nix diff tool
    p7zip # Compression tool
    powertop # Power consumption
    ripgrep # Fast grep
    rpi-imager # Raspberry Pi OS image writer
    taskwarrior3 # Task manager
    tig # git text-mode interface
    tldr # Help pages
    tree # Display directory struture
    unetbootin # Bootable USB creator
    unzip # Zip decompress
    usbutils # USB tools (lsusb)
    v4l-utils # Video for Linux utilities
    woeusb # Bootable USB creator for Windows media
    zip # Zip compress

    # Apps
    filezilla # FTP client
    meld # Diff tools
    obsidian # Notes
    remmina # Remove desktop client
    subversion # Software version control
    vlc # Media player

    # Browsers
    chromium

    # Fonts
    (google-fonts.override {
      fonts = [
        "Teko"
        "RedHatDisplay"
      ];
    })
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
    noto-fonts-emoji
    powerline-fonts
    twitter-color-emoji

    # Node
    nodejs

    # Python
    unstable.ruff # Formatter
    (python312.withPackages (ps: with ps; [ black flake8 pip pipx ]))

    # Compilers
    gcc
    pkgs.stdenv.cc.cc.lib # LD_LIBRARY_PATH set in bash.nix

    # Printing
    system-config-printer
  ];

  # Programs and configurations to be installed
  imports = [
    ./configs/abcde.nix
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
    ./configs/vscode.nix
    # ./configs/zsh.nix
  ];

  systemd.user.services.polybar = {
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
