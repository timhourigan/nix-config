{ pkgs, ... }:

{
  users.users.timh = {
    isNormalUser = true;
    description = "timh";
    # adb/Android: "adbusers"
    # Networking: "networkmanager"
    # Printers/Scanners: "lp"
    # Scanners: "scanner"
    # sudo: "wheel"
    extraGroups = [ "adbusers" "lp" "networkmanager" "scanner" "wheel" ];
    packages = with pkgs; [ firefox git vim ];
    shell = pkgs.bash;
    # FIXME Consider - zsh
    # Enable zsh system wide
    # programs.zsh.enable = true;
    # Include zsh in /etc/shells
    # environment.shells = with pkgs; [ zsh ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOdPJVS2P6fNEMuIAuJqCMtqLU4LAI50SeoAF5GyCFFl"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/Tztty6abMFos05TQbanvo+Y6uwZKNnhG1I+bkikgzeM7+Tz9Vx5xlodTqko71Ipn/dR66mpyADaPV0kE1MPdK7oBZdxaDKBGD/zo1Rm3fH4BVPk5z0g7cwaBKNRq8UvNcFy10ksNCeDZQYfMdWXnpYUj7WYjsIAmOV+FARz6NakmAsCh/A7vzBsFoFZ4JzayE/vGCHdQc1ecw6QF40yBqZA8Ufpft//VG2SfXPoLHlYFdTxp4AjvlMJ2mjoDnBem1n+6aBl2qMDA7PQqFse2mJLZhnCncuLImJH05rwCCPf1wEb1NpzpLwvPBt8cTNx/S/hJ4fQ5fmsxJlkzUdvOPCDM9yy/ITg++hrJHPGA9sdXRuO42OKoT25U65fCFM2PzrmSTPRLRsR4KxiPvMay4fQS4JfAOD5LOrecuLYMiL1rJrjzp/IaIgF5CylVx5NFlA4AzicmNI2A5/I2YeBX3yc2IAhcMjgTRYUbI0H9P21g4Yre+o4CSjuhmoO27eBtb4M02OnGXhzg7IsASDmyQRwJbqNyFAYnmS9tSX7H7BQ/+DbC7vak2sNidnJ8hc2jGtauQwsUeZlalYy3NM+ePL7eCm6GnYNQOFnnzAlYKBSTw+NymJY7WYOeb+woe2pgOPzK7fLggXgxxVlrsYpwbG1KyrCBP3l+Ie3HdCLxuw=="
    ];
  };

  # Groups
  users.groups = {
    home = {
      gid = 1001;
      members = [ "timh" ];
    };
  };
}
