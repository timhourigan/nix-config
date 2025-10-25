{ lib, ... }:

{
  options = {
    custom = {
      defaultUser = lib.mkOption {
        type = lib.types.str;
        default = "timh";
        description = "Default user";
      };
      internalDomain = lib.mkOption {
        type = lib.types.str;
        default = "rc.home";
        description = "Internal domain";
      };
    };
  };
}
