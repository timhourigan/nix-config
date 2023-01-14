{ lib, ... }:

{
  # FIXME - Doesn't appear to be having an effect
  dconf.settings = {
    "org/cinnamon/desktop/interface" = {
      text-scaling-factor = lib.hm.gvariant.mkDouble 1.3;
    };
  };
}

# dconf read /org/cinnamon/desktop/interface/text-scaling-factor
