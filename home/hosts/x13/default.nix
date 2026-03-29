{ pkgs, ... }:

{
  # Packages to be installed
  home.packages = with pkgs; [
    # Apps
    audacity # Audio editor
    avidemux # Video editor
    brasero # CD/DVD burner
    devede # CD/DVD creator
    font-manager # Font management
    freetube # Youtube client
    gimp # Image editor
    inkscape # SVG editor
    libreoffice # Office suite
    mqtt-explorer # MQTT client/explorer
    unstable.opencode # AI code editor
    telegram-desktop # Messaging
    scribus # Desktop publishing
    xorg.xhost # X11 access control (for distrobox GUI apps)
    zed-editor # Text editor
  ];

  # Allow local X11 connections for distrobox GUI apps
  systemd.user.services.xhost-local = {
    Unit = {
      Description = "Allow local X11 connections for distrobox";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.xorg.xhost}/bin/xhost +local:";
      RemainAfterExit = true;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Programs and configurations to be installed
  imports = [
    ../../configs/abcde.nix
  ];

  # Modules
  modules.home = {
    distrobox =
      let
        image = "debian:13";
        hm_amd64 = "db-hm-amd64";
        hm_aarch64 = "db-hm-aarch64";
        additional_packages = "locales make nix-bin nix-setup-systemd";
        # Init hooks
        # 1. Fix locale issues due to host being IE
        locales_hook = "echo en_IE.UTF-8 UTF-8 | sudo tee /etc/locale.gen && sudo locale-gen";
        # 2. Enable flakes and nix-command in container's nix.conf
        nix_conf_hook = "echo 'experimental-features = nix-command flakes' | sudo tee -a /etc/nix/nix.conf";
        # 3. Add nix-profile bin to PATH for all login shells
        # - Using base64 encode of `export PATH="$HOME/.nix-profile/bin:$PATH"`
        #   to avoid issues with quoting and variable expansion of $HOME and $PATH
        #   in the init_hooks string
        path_hook = "echo ZXhwb3J0IFBBVEg9IiRIT01FLy5uaXgtcHJvZmlsZS9iaW46JFBBVEgiCg== | base64 -d | sudo tee /etc/profile.d/nix-profile.sh";
        init_hooks = "${locales_hook} && ${nix_conf_hook} && ${path_hook}";
      in
      {
        enable = true;
        containers.${hm_amd64} = {
          inherit image;
          hostname = hm_amd64;
          home = "$HOME/distrobox/${hm_amd64}";
          additional_flags = "--platform linux/amd64";
          inherit additional_packages;
          inherit init_hooks;
        };
        containers.${hm_aarch64} = {
          inherit image;
          hostname = hm_aarch64;
          home = "$HOME/distrobox/${hm_aarch64}";
          additional_flags = "--platform linux/arm64";
          inherit additional_packages;
          inherit init_hooks;
        };
      };
    ghostty.enable = true;
    polybar.enable = true;
    rofi.enable = true;
    vscode.enable = true;
  };
}
