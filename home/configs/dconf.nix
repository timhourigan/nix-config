{ lib, ... }:

{
  # FIXME - Doesn't appear to be having an effect
  # dconf read /org/cinnamon/desktop/interface/text-scaling-factor
  dconf.settings = {
    "org/cinnamon/desktop/interface" = {
      text-scaling-factor = lib.hm.gvariant.mkDouble 1.3000000000000003;
    };
  };
}
