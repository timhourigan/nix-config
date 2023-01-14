{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    vimAlias = true;
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
      vimPlugins.coc-python
      vimPlugins.coc-pyright
      vimPlugins.coc-go
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
}
