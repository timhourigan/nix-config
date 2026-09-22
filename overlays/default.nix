{ inputs, ... }:
let
  # Latest Claude Code
  #
  # To update: curl -fsSL "https://downloads.claude.ai/claude-code-releases/$(curl -fsSL https://downloads.claude.ai/claude-code-releases/latest)/manifest.zst.json" | jq -j . > overlays/claude-code-manifest.json
  claudeCodeManifest = builtins.fromJSON (builtins.readFile ./claude-code-manifest.json);

  claudeCodeLatest = final: prev: {
    claude-code = prev.claude-code.overrideAttrs (
      _old:
      let
        platformKey = "${final.stdenv.hostPlatform.node.platform}-${final.stdenv.hostPlatform.node.arch}";
        platformEntry = claudeCodeManifest.platforms.${platformKey};
      in
      {
        inherit (claudeCodeManifest) version;
        src = final.fetchurl {
          url = "https://downloads.claude.ai/claude-code-releases/${claudeCodeManifest.version}/${platformKey}/${platformEntry.binary}";
          sha256 = platformEntry.checksum;
        };
      }
    );
  };
in
{

  # Make unstable packages available at pkgs.unstable
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final.stdenv.hostPlatform) system;
      config.allowUnfree = true;
      overlays = [ claudeCodeLatest ];
    };
  };

  # Make pinned packages available at pkgs.pinned
  pinned-packages = final: _prev: {
    pinned = import inputs.nixpkgs-pinned {
      inherit (final.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };
  };

  # WORKAROUND - pipx test failures (https://github.com/NixOS/nixpkgs/issues/522307)
  pipx-fix = _final: prev: {
    python313 = prev.python313.override (old: {
      packageOverrides = prev.lib.composeExtensions (old.packageOverrides or (_: _: { })) (
        _pyself: pysuper: {
          pipx = pysuper.pipx.overridePythonAttrs (_old: {
            disabledTests = (_old.disabledTests or [ ]) ++ [
              "test_fix_package_name"
              "test_parse_specifier_for_metadata"
            ];
          });
        }
      );
    });
  };
}
