{ inputs, outputs, pkgs, ... }:

{
  imports = [
    ../modules/home
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
    dmidecode # DMI table decoder (hardware info)
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
    lshw # Hardware information
    mediainfo # Media file information
    nmap # Network exploration
    p7zip # Compression tool
    pciutils # PCI device utilities (lspci)
    powertop # Power consumption
    ripgrep # Fast grep
    # FIXME - Broken in nixpkgs 25.05 - https://github.com/NixOS/nixpkgs/issues/461249
    unstable.rpi-imager # Raspberry Pi OS image writer
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

  # Modules
  modules.home = {
    alacritty.enable = true;
    autojump.enable = true;
    bash.enable = true;
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
