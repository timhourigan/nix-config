_:

{
  # Settings configuration - https://nix.dev/manual/nix/2.28/command-ref/conf-file.html
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # Download buffer size of 256MiB to prevent stalls during download
    # Default is 64MiB
    download-buffer-size = 268435456;
    # Allow packages to be pushed from other systems e.g.
    # nixos-rebuild build --target-host <hostname> --flake .
    trusted-users = [ "timh" ];
  };
}
