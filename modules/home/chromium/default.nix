{
  config,
  lib,
  ...
}:

let
  cfg = config.modules.home.chromium;
in
{
  options = {
    modules.home.chromium = {
      enable = lib.mkEnableOption "Chromium" // {
        description = "Enable Chromium";
        default = false;
      };
      extensions = lib.mkOption {
        type = lib.types.listOf (lib.types.coercedTo lib.types.str (id: { inherit id; }) lib.types.attrs);
        default = [ ];
        description = "Chromium extensions to install, as Chrome Web Store IDs or Home Manager extension attrsets";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.chromium = {
      enable = true;
      inherit (cfg) extensions;
    };
  };
}
