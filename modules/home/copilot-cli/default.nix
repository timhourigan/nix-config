{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.home.copilot-cli;
  jsonFormat = pkgs.formats.json { };
in
{
  options = {
    modules.home.copilot-cli = {
      enable = lib.mkEnableOption "copilot-cli" // {
        description = "Enable Copilot CLI";
        default = false;
      };
      package = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = pkgs.github-copilot-cli;
        description = "Package to use (null to skip installing)";
      };

      configDir = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/.copilot";
        description = "Directory holding configuration files";
      };

      enableMcpIntegration = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to integrate MCP servers from programs.mcp.servers";
      };

      settings = lib.mkOption {
        inherit (jsonFormat) type;
        default = { };
        description = "JSON configuration written to config.json";
      };

      context = lib.mkOption {
        type = lib.types.either lib.types.lines lib.types.path;
        default = "";
        description = ''
          Global instructions, written to copilot-instructions.md.
          Either inline content as a string or a path to a file.
        '';
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

      agents = lib.mkOption {
        type = lib.types.either (lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path)) lib.types.path;
        default = { };
        description = "Custom agents (attrset or path to directory)";
      };

      skills = lib.mkOption {
        type = lib.types.either (lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path)) lib.types.path;
        default = { };
        description = "Custom skills (attrset or path to directory)";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.github-copilot-cli = {
      enable = true;
      inherit (cfg)
        package
        configDir
        enableMcpIntegration
        settings
        context
        mcpServers
        lspServers
        agents
        skills
        ;
    };
  };
}
