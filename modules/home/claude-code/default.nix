{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.home.claude-code;
  jsonFormat = pkgs.formats.json { };
in
{
  options = {
    modules.home.claude-code = {
      enable = lib.mkEnableOption "claude-code" // {
        description = "Enable Claude Code";
        default = false;
      };

      package = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = pkgs.claude-code;
        description = "The claude-code package to use (null to skip installing)";
      };

      configDir = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/.claude";
        description = "Directory holding Claude Code's configuration files";
      };

      enableMcpIntegration = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to integrate MCP servers from programs.mcp.servers";
      };

      settings = lib.mkOption {
        inherit (jsonFormat) type;
        default = { };
        description = "JSON configuration for Claude Code settings.json";
      };

      mcpServers = lib.mkOption {
        type = lib.types.attrsOf jsonFormat.type;
        default = { };
        description = "MCP (Model Context Protocol) servers configuration";
      };

      lspServers = lib.mkOption {
        type = lib.types.attrsOf jsonFormat.type;
        default = { };
        description = "LSP (Language Server Protocol) servers configuration";
      };

      context = lib.mkOption {
        type = lib.types.either lib.types.lines lib.types.path;
        default = "";
        description = ''
          Global context for Claude Code (written to CLAUDE.md).
          Either inline content as a string or a path to a file.
        '';
      };

      plugins = lib.mkOption {
        type = with lib.types; listOf (either package path);
        default = [ ];
        description = "List of plugins to use when running Claude Code";
      };

      marketplaces = lib.mkOption {
        type = with lib.types; attrsOf (either package path);
        default = { };
        description = "Custom marketplaces for Claude Code plugins";
      };

      agents = lib.mkOption {
        type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
        default = { };
        description = "Custom agents for Claude Code (name -> content or path)";
      };

      agentsDir = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to a directory containing agent files";
      };

      commands = lib.mkOption {
        type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
        default = { };
        description = "Custom commands for Claude Code (name -> content or path)";
      };

      commandsDir = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to a directory containing command files";
      };

      hooks = lib.mkOption {
        type = lib.types.attrsOf lib.types.lines;
        default = { };
        description = "Custom hooks for Claude Code (name -> script content)";
      };

      hooksDir = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to a directory containing hook files";
      };

      rules = lib.mkOption {
        type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
        default = { };
        description = "Modular rule files for Claude Code (name -> content or path)";
      };

      rulesDir = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to a directory containing rule files";
      };

      skills = lib.mkOption {
        type = lib.types.either (lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path)) lib.types.path;
        default = { };
        description = "Custom skills for Claude Code (attrset or path to directory)";
      };

      outputStyles = lib.mkOption {
        type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
        default = { };
        description = "Custom output styles for Claude Code (name -> content or path)";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
      inherit (cfg)
        package
        configDir
        enableMcpIntegration
        settings
        mcpServers
        lspServers
        context
        plugins
        marketplaces
        agents
        commands
        hooks
        rules
        skills
        outputStyles
        ;
    }
    // lib.optionalAttrs (cfg.agentsDir != null) { inherit (cfg) agentsDir; }
    // lib.optionalAttrs (cfg.commandsDir != null) { inherit (cfg) commandsDir; }
    // lib.optionalAttrs (cfg.hooksDir != null) { inherit (cfg) hooksDir; }
    // lib.optionalAttrs (cfg.rulesDir != null) { inherit (cfg) rulesDir; };
  };
}
