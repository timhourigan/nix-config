{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.home.opencode;
  jsonFormat = pkgs.formats.json { };
in
{
  options = {
    modules.home.opencode = {
      enable = lib.mkEnableOption "opencode" // {
        description = "Enable OpenCode";
        default = false;
      };

      package = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = pkgs.opencode;
        description = "The opencode package to use (null to skip installing)";
      };

      extraPackages = lib.mkOption {
        type = with lib.types; listOf package;
        default = [ ];
        description = "Extra packages available to OpenCode";
      };

      enableMcpIntegration = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to integrate MCP servers from programs.mcp.servers";
      };

      settings = lib.mkOption {
        inherit (jsonFormat) type;
        default = { };
        description = "JSON configuration for OpenCode's opencode.json";
      };

      tui = lib.mkOption {
        inherit (jsonFormat) type;
        default = { };
        description = "TUI-specific configuration for OpenCode's tui.json";
      };

      web = {
        enable = lib.mkEnableOption "opencode web service";

        extraArgs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Extra arguments to pass to the opencode serve command";
        };

        environmentFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Path to an EnvironmentFile for the opencode web service (e.g. for OPENCODE_SERVER_PASSWORD)";
        };
      };

      context = lib.mkOption {
        type = lib.types.either lib.types.lines lib.types.path;
        default = "";
        description = ''
          Global context for OpenCode (written to AGENTS.md).
          Either inline content as a string or a path to a file.
        '';
      };

      commands = lib.mkOption {
        type = lib.types.either (lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path)) lib.types.path;
        default = { };
        description = "Custom commands for OpenCode (name -> content or path)";
      };

      agents = lib.mkOption {
        type = lib.types.either (lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path)) lib.types.path;
        default = { };
        description = "Custom agents for OpenCode (name -> content or path)";
      };

      skills = lib.mkOption {
        type = lib.types.either (lib.types.attrsOf (
          lib.types.oneOf [
            lib.types.lines
            lib.types.path
            lib.types.str
          ]
        )) lib.types.path;
        default = { };
        description = "Custom skills for OpenCode (attrset or path to directory)";
      };

      themes = lib.mkOption {
        type = lib.types.either (lib.types.attrsOf (lib.types.either jsonFormat.type lib.types.path)) lib.types.path;
        default = { };
        description = "Custom themes for OpenCode (attrset or path to directory)";
      };

      tools = lib.mkOption {
        type = lib.types.either (lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path)) lib.types.path;
        default = { };
        description = "Custom tools for OpenCode (name -> content or path)";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      inherit (cfg)
        package
        extraPackages
        enableMcpIntegration
        settings
        tui
        web
        context
        commands
        agents
        skills
        themes
        tools
        ;
    };
  };
}
