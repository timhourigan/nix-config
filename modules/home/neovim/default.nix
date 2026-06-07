{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.home.neovim;
in
{
  options = {
    modules.home.neovim = {
      enable = lib.mkEnableOption "Neovim" // {
        description = "Enable Neovim";
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      vimAlias = true;
      withRuby = false; # Required with HM 26.05 when state version is older
      withPython3 = true; # Required with HM 26.05 when state version is older
      coc.enable = true;
      coc.settings = {
        "python.linting.enabled" = true;
        "python.linting.flake8Enabled" = true;
      };
      plugins = with pkgs; [
        # Appearance
        vimPlugins.vim-airline
        vimPlugins.vim-airline-themes
        vimPlugins.vim-devicons
        vimPlugins.nerdtree
        # Git
        vimPlugins.vim-fugitive
        # Languages
        vimPlugins.vim-nix
        # CoC / Conquer of Completion
        vimPlugins.coc-pairs
        vimPlugins.coc-snippets
        vimPlugins.coc-pyright
        vimPlugins.coc-yaml
        vimPlugins.coc-json
        vimPlugins.coc-prettier
        vimPlugins.coc-markdownlint
        # Utils
        vimPlugins.fzf-vim
      ];
      extraConfig = ''
        " Airline
        let g:airline_powerline_fonts = 1
        if !exists('g:airline_symbols')
            let g:airline_symbols = {}
        endif
        let g:airline_theme = 'minimalist'
      '';
    };
  };
}
