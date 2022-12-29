{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [
      # Search with:
      # https://search.nixos.org/packages?channel=22.05type=packages&query=vscode-extensions
      # Languages
      wholroyd.jinja # Jinja
      yzhang.markdown-all-in-one # Markdown
      bbenoist.nix # Nix
      ms-python.python # Python
      matklad.rust-analyzer # Rust
      hashicorp.terraform # Terraform
      redhat.vscode-yaml # YAML
      # Git
      eamodio.gitlens
      donjayamanne.githistory
      github.vscode-pull-request-github
      # Editor appearance
      johnpapa.vscode-peacock
      pkief.material-icon-theme
      dracula-theme.theme-dracula
      # Formatting
      esbenp.prettier-vscode
      editorconfig.editorconfig
      # Spelling
      streetsidesoftware.code-spell-checker
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
    };
  };
}
