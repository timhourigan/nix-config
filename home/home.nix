{ config, inputs, outputs, pkgs, ... }:

{
  nixpkgs = {
    overlays = [
      # Allow unstable packages at unstable.<package>
      outputs.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "ventoy-1.1.05" # https://github.com/ventoy/Ventoy/issues/3224
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

  # Packages to be installed
  home.packages = with pkgs; [
    # Tools
    age # Age encryption/decryption
    appimage-run # Run AppImage files
    bat # `cat` clone
    bottom # Display process information (`top` alternative)
    ddrescue # dd, with extra functionality
    dig # DNS lookup
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
    pciutils # PCI device utilities (lspci)
    powertop # Power consumption
    ripgrep # Fast grep
    rpi-imager # Raspberry Pi OS image writer
    screen # Terminal multiplexer
    sops # Secrets management
    ssh-to-age # SSH to Age key converter
    taskwarrior3 # Task manager
    tig # git text-mode interface
    tldr # Help pages
    tree # Display directory structure
    unetbootin # Bootable USB creator
    unzip # Zip decompress
    usbutils # USB tools (lsusb)
    v4l-utils # Video for Linux utilities
    ventoy # Bootable USB creator
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

    pkgs.nerd-fonts._0xproto
    pkgs.nerd-fonts.dejavu-sans-mono
    pkgs.nerd-fonts.droid-sans-mono
    pkgs.nerd-fonts.fira-code
    pkgs.nerd-fonts.hack
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.nerd-fonts.liberation
    pkgs.nerd-fonts.terminess-ttf

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

    # NUR modules
    inputs.nur.modules.homeManager.default
  ];

  systemd.user.services.polybar = {
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
