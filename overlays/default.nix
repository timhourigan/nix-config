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

  # Make personal fork packages available at pkgs.personal
  personal-packages = final: _prev: {
    personal = import inputs.nixpkgs-personal {
      inherit (final.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };
  };
}
