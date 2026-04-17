{
  config,
  lib,
  pkgs,
  ...
}:

# TODO: Add the following options when home-manager 26.05 is released:
# - enableMcpIntegration
# - lspServers
# - rules / rulesDir
# - plugins
# - marketplaces
# - outputStyles

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
        default = pkgs.claude-code;
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

      memory = {
        text = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.addCheck lib.types.lines (_: cfg.memory.source == null)
          );
          default = null;
          description = "Inline memory content for CLAUDE.md. Mutually exclusive with `memory.source`; evaluation fails if both are set.";
        };

        source = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.addCheck lib.types.path (_: cfg.memory.text == null)
          );
          default = null;
          description = "Path to a file containing memory content for CLAUDE.md. Mutually exclusive with `memory.text`; evaluation fails if both are set.";
        };
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
    };
  };

  config = lib.mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
      inherit (cfg)
        package
        settings
        mcpServers
        memory
        agents
        commands
        hooks
        skills
        ;
    }
    // lib.optionalAttrs (cfg.agentsDir != null) { inherit (cfg) agentsDir; }
    // lib.optionalAttrs (cfg.commandsDir != null) { inherit (cfg) commandsDir; }
    // lib.optionalAttrs (cfg.hooksDir != null) { inherit (cfg) hooksDir; }
    // lib.optionalAttrs (cfg.skillsDir != null) { inherit (cfg) skillsDir; };
  };
}
