{ config, lib, ... }:

let
  cfg = config.modules.home.claude-code;
in
{
  options = {
    modules.home.claude-code = {
      enable = lib.mkEnableOption "claude-code" // {
        description = "Enable Claude Code";
        default = false;
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = config.programs.claude-code.package;
        description = "The claude-code package to use";
      };

      settings = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "JSON configuration for Claude Code settings.json";
      };

      mcpServers = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "MCP (Model Context Protocol) servers configuration";
      };

      lspServers = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "LSP (Language Server Protocol) servers configuration";
      };

      rules = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Modular rule files for Claude Code";
      };

      rulesDirs = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to a directory containing rule files for Claude Code";
      };

      agents = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Custom agents for Claude Code";
      };

      agentsDir = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to a directory containing agent files for Claude Code";
      };

      commands = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Custom commands for Claude Code";
      };

      commandsDir = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to a directory containing command files for Claude Code";
      };

      hooks = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Custom hooks for Claude Code";
      };

      hooksDir = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to a directory containing hook files for Claude Code";
      };

      skills = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Custom skills for Claude Code";
      };

      skillsDir = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to a directory containing skill directories for Claude Code";
      };

      plugins = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of plugins to use when running Claude Code";
      };

      marketplaces = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Custom marketplaces for Claude Code plugins";
      };

      outputStyles = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Custom output styles for Claude Code";
      };

      memory = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Memory configuration for Claude Code";
      };

      enableMcpIntegration = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to integrate MCP servers config from programs.mcp.servers";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
      inherit (cfg)
        package
        settings
        mcpServers
        lspServers
        rules
        agents
        commands
        hooks
        skills
        plugins
        marketplaces
        outputStyles
        memory
        enableMcpIntegration
        ;
    }
    // lib.optionalAttrs (cfg.rulesDirs != null) { rulesDir = cfg.rulesDirs; }
    // lib.optionalAttrs (cfg.agentsDir != null) { inherit (cfg) agentsDir; }
    // lib.optionalAttrs (cfg.commandsDir != null) { inherit (cfg) commandsDir; }
    // lib.optionalAttrs (cfg.hooksDir != null) { inherit (cfg) hooksDir; }
    // lib.optionalAttrs (cfg.skillsDir != null) { inherit (cfg) skillsDir; };
  };
}
