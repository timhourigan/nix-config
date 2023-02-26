{ pkgs, ... }:

{
  programs.git = {
    package = pkgs.gitAndTools.gitFull;
    enable = true;
    userName = "Tim Hourigan";
    userEmail = "1819176+timhourigan@users.noreply.github.com";
    aliases = {
      ci = "commit";
      co = "checkout";
      br = "branch";
      st = "status";
      pub = "push origin -u";
    };
    extraConfig = { credential = { helper = "libsecret"; }; };
  };
}
