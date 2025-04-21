{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    # Let Nix manage  ~/.vscode/extensions/extensions.json
    # https://github.com/nix-community/home-manager/issues/5372
    mutableExtensionsDir = false;
    extensions = with pkgs.vscode-extensions; [
      # Search with:
      # https://search.nixos.org/packages?channel=22.05type=packages&query=vscode-extensions
      # Languages
      wholroyd.jinja # Jinja
      ms-vscode.makefile-tools # Makefile
      yzhang.markdown-all-in-one # Markdown
      bbenoist.nix # Nix
      ms-python.python # Python
      rust-lang.rust-analyzer # Rust
      hashicorp.terraform # Terraform
      redhat.vscode-yaml # YAML
      # Git
      eamodio.gitlens
      donjayamanne.githistory
      # Github
      github.copilot
      github.copilot-chat
      github.vscode-pull-request-github
      github.vscode-github-actions
      # Editor appearance
      johnpapa.vscode-peacock
      pkief.material-icon-theme
      dracula-theme.theme-dracula
      # Formatting
      esbenp.prettier-vscode
      editorconfig.editorconfig
      # Spelling
      streetsidesoftware.code-spell-checker
      # Remote SSH development
      ms-vscode-remote.remote-ssh
    ];
    userSettings = {
      # Material Icons
      "workbench.iconTheme" = "material-icon-theme";
      # No startup splashscreen
      "workbench.startupEditor" = "none";
      # Git config
      "git.confirmSync" = false;
      # No confirm on drag and drop
      "explorer.confirmDragAndDrop" = false;
      # No confirm on delete
      "explorer.confirmDelete" = false;
      # Turn off telemetry
      "telemetry.telemetryLevel" = "off";
      # Turn off Redhat telemetry
      "redhat.telemetry.enabled" = false;
      # Turn off auto-updates, let Nix manage
      "update.mode" = "none";
      # Trim newlines at end of file
      "files.trimFinalNewlines" = true;
      # Display trimmed whitespace
      "diffEditor.ignoreTrimWhitespace" = false;
    };
  };
}
