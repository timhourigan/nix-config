{ pkgs, ... }:

{
  # System packages
  environment.systemPackages = with pkgs; [
    bash-completion
    file
    git
    git-crypt
    gnumake
    nvd # Nix package version diff
    nix-output-monitor # Nix build output monitor
    vim
    wget
  ];
}
