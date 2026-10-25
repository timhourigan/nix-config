{ pkgs, ... }:
# UI UX Pro Max skill family for the pi coding agent.
#
# The upstream repo (nextlevelbuilder/ui-ux-pro-max-skill) is not a Nix flake,
# so it cannot be a flake input; fetch it as a checksum-pinned source instead
# and link the skills into ~/.agents/skills (pi's skill root).
#
# To update: bump `rev` (+ `sha256` below), then rebuild. Get the new hash
# from the build error when sha256 is wrong, or `nix-prefetch-url --unpack`.
let
  src = pkgs.fetchFromGitHub {
    owner = "nextlevelbuilder";
    repo = "ui-ux-pro-max-skill";
    # HEAD of main, pinned 2026-10-23.
    rev = "d14efff8ed1faa4187f004f79926f428c8074ec7";
    sha256 = "sha256-2Mvf7vq+RW9hNfJN00zL1zX5sacU9vSSP4HVgOYOSYM=";
  };

  skills = [ "banner-design" "brand" "design" "design-system" "slides" "ui-styling" "ui-ux-pro-max" ];
in
{
  home.file = builtins.listToAttrs (map
    (name: {
      name = ".agents/skills/${name}";
      value.source = "${src}/.claude/skills/${name}";
    })
    skills);
}
