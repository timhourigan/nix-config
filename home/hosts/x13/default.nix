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
    zed-editor # Text editor
  ];

  # Programs and configurations to be installed
  imports = [
    ../../configs/abcde.nix
  ];

  # Modules
  modules.home = {
    distrobox =
      let
        image = "debian:13";
        additional_packages = "locales make nix-bin nix-setup-systemd";
        amd64_container = "amd64linux-t";
        aarch64_container = "aarch64linux-t";
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
        base_hooks = "${locales_hook} && ${nix_conf_hook} && ${path_hook}";
        # 4. Register zsh in /etc/shells, set as login shell, and create empty .zshrc
        #    to suppress the new user wizard
        zsh_hook =
          container:
          "echo /usr/bin/zsh | sudo tee -a /etc/shells && sudo chsh -s /usr/bin/zsh $(whoami) && touch $HOME/distrobox/${container}/.zshrc";
        # 5. Override distrobox's $SHELL mirroring back to bash
        bash_hook = "sudo chsh -s /bin/bash $(whoami)";
      in
      {
        enable = true;
        containers."${amd64_container}" = {
          inherit image;
          hostname = amd64_container;
          home = "$HOME/distrobox/${amd64_container}";
          additional_flags = "--platform linux/amd64";
          additional_packages = "${additional_packages} zsh";
          init_hooks = "${base_hooks} && ${zsh_hook amd64_container}";
        };
        containers."${aarch64_container}" = {
          inherit image additional_packages;
          hostname = aarch64_container;
          home = "$HOME/distrobox/${aarch64_container}";
          additional_flags = "--platform linux/arm64";
          init_hooks = "${base_hooks} && ${bash_hook}";
        };
      };
    ghostty.enable = true;
    polybar.enable = true;
    rofi.enable = true;
    tmux.shell = "${pkgs.zsh}/bin/zsh";
    vscode.enable = true;
    zsh.enable = true;
  };
}
