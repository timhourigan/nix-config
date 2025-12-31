{ inputs, ... }: {

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
}
