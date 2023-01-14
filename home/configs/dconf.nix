{ lib, ... }:

{
  dconf.settings = {
    "org/cinnamon/desktop/interface" = {
        text-scaling-factor = lib.hm.gvariant.mkDouble 1.3;
    };
  };
}

# dconf read /org/cinnamon/desktop/interface/text-scaling-factor
