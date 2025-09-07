{ lib, ... }:

{
  options = {
    custom = {
      internalDomain = lib.mkOption {
        type = lib.types.str;
        default = "rc.home";
        description = "Internal domain";
      };
    };
  };

  imports = [
    ./localisation.nix
    ./system-packages.nix
    ./users-groups.nix
  ];
}
