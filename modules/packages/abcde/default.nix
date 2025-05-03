{ config, lib, options, pkgs, ... }:

let
  cfg = config.modules.packages.abcde;
in
{
  options = {
    modules.packages.abcde = {
      enable = lib.mkEnableOption "abcde" // {
        description = "Enable abcde CD ripper package";
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      abcde
      cddiscid
      cdparanoia
      cdrtools
      flac
      glyr
      imagemagick
      lame
      vorbis-tools
    ];
  };
}
