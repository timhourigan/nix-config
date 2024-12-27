{ ... }:

# Garbage collection

{
    nix.gc = {
        automatic = true;
        persistent = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
    };
}
