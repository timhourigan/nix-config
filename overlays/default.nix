{ inputs, ... }:
{

  # Make unstable packages available at pkgs.unstable
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final.stdenv.hostPlatform) system;
      config.allowUnfree = true;
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
    python313 = prev.python313.override {
      packageOverrides = _pyself: pysuper: {
        pipx = pysuper.pipx.overridePythonAttrs (_old: {
          disabledTests = (_old.disabledTests or [ ]) ++ [
            "test_fix_package_name"
            "test_parse_specifier_for_metadata"
          ];
        });
      };
    };
  };
}
