{ pkgs, ... }:

{
  targets.genericLinux.enable = true;

  # Non-NixOS GPU driver env (mesa/libglvnd/… linked into /run/opengl-driver)
  # is on by default when genericLinux is enabled — nothing we install needs
  # it, and it only prints a setup hint on every switch. Disabled; re-enable
  # if you start installing Nix apps that need their own GL drivers.
  targets.genericLinux.gpu.enable = false;

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  home = {
    # Home Manager release
    stateVersion = "24.05";

    # Packages to be installed
    packages = with pkgs; [
      # Utils
      age # age-keygen: encryption keys for sops + home-k8s secrets
      awscli2
      bat # `cat` clone
      bitwarden-desktop # Password Manager
      bottom # Display process information (`top` alternative)
      caddy # Web server
      curl # I want a newer version than the one provided by Ubuntu
      dive # Docker image explorer
      dust # Disk space usage (`du` alternative)
      eza # File listing (`ls` alternative)
      fd # Find files/folders (`find` alternative)
      feh # Command line image viewer
      flyctl # Fly.io CLI
      gcc # C compiler
      gitleaks # Git repository secrets checker
      htop # Display process information (`top` alternative)
      jq # Command line JSON parser
      just # Command runner
      loco # Loco CLI
      sea-orm-cli # Sea ORM CLI
      sops # Encrypt/decrypt secrets (home-k8s, .sops.yaml)
      fastfetch # System information
      nemo # File manager
      nixfmt # Nix formatter
      # nixfmt-rfc-style new RFC 166-style formatter
      niv # Nix dependency management
      nmap # Network exploration
      ripgrep # Fast grep
      ruff # Fast Python linter
      taskwarrior2 # Task manager
      tig # git text-mode interface
      tcpdump # Network packet analyzer
      tldr # Help pages
      tree # Display directory struture
      wget # Download files

      # For scones.ie
      postgresql_16 # I just want to install libpq - waiting on https://github.com/NixOS/nixpkgs/issues/61580
      libpqxx # C++ library for PostgreSQL. Needed for scones.ie for some reason
      sqlite # SQLite database CLI
      # shell doesnt seem to work
      diesel-cli
      # Apps
      tailscale # VPN
      filezilla # FTP client
      gimp # Image editor
      libreoffice # Office suite
      meld # Diff tools
      vlc # Media player
      yt-dlp # Download videos from YouTube

      # Browsers
      chromium
      # firefox

      # Fonts
      # 2026 nixpkgs: nerdfonts.override is gone; each family is its own
      # package under pkgs.nerd-fonts. No Terminus family exists (dropped).
      nerd-fonts.dejavu-sans-mono
      nerd-fonts.droid-sans-mono
      nerd-fonts.fira-code
      nerd-fonts.hack
      nerd-fonts.jetbrains-mono
      nerd-fonts.liberation
      twitter-color-emoji
      noto-fonts-color-emoji
      powerline-fonts

      podman
      podman-compose

      # LibreCAD — dnf install conflicts with libredwg's dwg2dxf; use Nix
      # instead (2.2.1.x always, no rpm file fights).
      librecad

      # Languages
      nodejs
      rustup
      nixd
      nixpkgs-fmt

      # Coding agent (pi) — replaces the stray global npm install in
      # ~/.local/lib/node_modules. Extensions still live in ~/.pi/agent/npm/
      # and are updated via `pi update --extensions`.
      pi-coding-agent

      ansible-lint
      ansible
      # python311 → sphinx 9.1 dropped py3.11 support; use python312
      (python312.withPackages (ps: with ps; [
        packer
        pip
        tox
        podman
        podman-compose
        podman-desktop
      ]))

      # FIXME How to add this to menus, with icon?
      signal-desktop # Encryted messaging
      spotify
      vim
      wireshark-cli
      wireguard-go
      zola
    ];
  };
  # Allow fontconfig to discover installed fonts and configurations
  fonts.fontconfig.enable = true;

  # Programs and configurations to be installed
  imports = [
    ./configs/alacritty.nix
    ./configs/autojump.nix
    ./configs/bash.nix
    # ./configs/dconf.nix
    ./configs/direnv.nix
    ./configs/firefox.nix
    ./configs/fzf.nix
    ./configs/gh.nix
    ./configs/git.nix
    ./configs/neovim.nix
    ./configs/polybar.nix
    ./configs/rofi.nix
    ./configs/ssh.nix
    ./configs/starship.nix
    ./configs/tmux.nix
    ./configs/ui-ux-pro-max-skill.nix
    ./configs/vscode.nix
    ./configs/zsh.nix
  ];

  systemd.user.services.polybar = {
    Install.WantedBy = [ "graphical-session.target" ];
  };

}
