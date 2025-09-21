{ ... }:

{
  imports = [
    ../../../modules/home
  ];

  # Modules
  modules = {
    home.vscode.enable = true;
  };
}
