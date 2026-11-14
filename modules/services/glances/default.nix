{
  lib,
  config,
  pkgs,
  ...
}:

# Glances monitoring service
# https://github.com/nicolargo/glances

let
  cfg = config.modules.services.glances;
in
{
  options = {
    modules.services.glances = {
      enable = lib.mkEnableOption "glances" // {
        description = "Enable glances monitoring service";
        default = false;
      };
      webserver = lib.mkOption {
        description = "Enable webserver";
        type = lib.types.bool;
        default = true;
      };
      port = lib.mkOption {
        description = "Port";
        type = lib.types.int;
        default = 61208;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.glances = {
      enable = true;
      # WORKAROUND 20261114 - Drop optional python-jose (insecure, CVE-2026-120459); skip flaky REST server tests
      package = pkgs.glances.overridePythonAttrs (old: {
        dependencies = lib.filter (d: (d.pname or "") != "python-jose") old.dependencies;
        disabledTestPaths = old.disabledTestPaths or [ ] ++ [
          "tests/test_restful.py"
          "tests/test_browser_restful.py"
        ];
      });
      openFirewall = true;
      inherit (cfg) port;
      extraArgs = if cfg.webserver then [ "--webserver" ] else [ ];
    };
  };
}
