{ lib, pkgs, ... }:

{
  home.packages =
    with pkgs;
    # All platforms
    [
      # Tools
      age # Age encryption/decryption
      bat # `cat` clone
      bottom # Display process information (`top` alternative)
      dig # DNS lookup
      dust # Disk space usage (`du` alternative)
      eza # File listing (`ls` alternative)
      fastfetch # System information
      fd # Find files/folders (`find` alternative)
      ffmpeg-full # Audio video manipulation
      gitleaks # Git repository secrets checker
      htop # Display process information (`top` alternative)
      jq # Command line JSON parser
      mediainfo # Media file information
      nmap # Network exploration
      p7zip # Compression tool
      ripgrep # Fast grep
      screen # Terminal multiplexer
      sops # Secrets management
      ssh-to-age # SSH to Age key converter
      taskwarrior3 # Task manager
      tig # git text-mode interface
      tldr # Help pages
      tree # Display directory structure
      unzip # Zip decompress
      zip # Zip compress

      # Apps
      subversion # Software version control

      # Fonts
      (google-fonts.override {
        fonts = [
          "Teko"
          "RedHatDisplay"
        ];
      })

      nerd-fonts._0xproto
      nerd-fonts.dejavu-sans-mono
      nerd-fonts.droid-sans-mono
      nerd-fonts.fira-code
      nerd-fonts.hack
      nerd-fonts.jetbrains-mono
      nerd-fonts.liberation
      nerd-fonts.terminess-ttf

      noto-fonts-color-emoji
      powerline-fonts
      twitter-color-emoji
      xkcd-font

      # Node
      nodejs

      # Python
      unstable.ruff # Formatter
      (python312.withPackages (
        ps: with ps; [
          black
          flake8
          pip
          pipx
        ]
      ))
    ]
    # Linux-only platforms
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      # Tools
      appimage-run # Run AppImage files
      ddrescue # dd, with extra functionality
      dmidecode # DMI table decoder (hardware info)
      feh # Command line image viewer
      gparted # Disk partition tool
      hdparm # Disk utility (set/get parameters, read-only speed test)
      lshw # Hardware information
      pciutils # PCI device utilities (lspci)
      powertop # Power consumption
      rpi-imager # Raspberry Pi OS image writer
      usbutils # USB tools (lsusb)
      v4l-utils # Video for Linux utilities
      ventoy # Bootable USB creator

      # Apps
      chromium # Web browser
      filezilla # FTP client
      meld # Diff tools
      obsidian # Notes
      remmina # Remote desktop client
      vlc # Media player

      # Compilers
      gcc # C/C++ compiler
      stdenv.cc.cc.lib # LD_LIBRARY_PATH set in bash.nix

      # Printing
      system-config-printer
    ]
    # x86_64-only platforms
    ++ lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
      unetbootin # Bootable USB creator
      woeusb # Bootable USB creator for Windows media
    ];
}
