_:

{
  # Settings configuration - https://nix.dev/manual/nix/2.28/command-ref/conf-file.html
  nix.settings = {
    # System has eight cores, allow six to be used during builds, to prevent overloading
    max-jobs = 3; # Number of concurrent jobs
    cores = 2; # Number of CPU cores per job
  };
}
