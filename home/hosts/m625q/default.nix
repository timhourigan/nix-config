{ ... }:

{
  imports = [
    ../modules/home
  ];

  # Modules
  modules = {
    home.bash.enable = false;
    home.zsh.enable = true;
  };
}
