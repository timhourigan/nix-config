{ lib, config, pkgs, ... }:

let
  motd = pkgs.writeShellScriptBin "motd" ''
    #!/usr/bin/env bash

    # Colours and formatting
    RED="\e[31m"
    GREEN="\e[32m"
    BOLD="\e[1m"
    ENDCOLOUR="\e[0m"

    # OS Information
    source /etc/os-release
    NIX_BUILD_TIME=$(stat -c %y /run/current-system | cut -d. -f1)

    # CPU
    CPU_NAME=$(awk -F': ' '/model name/ {print $2; exit}' /proc/cpuinfo)
    CPU_CORES=$(nproc)
    CPU_LOAD1=$(awk '{print $1}' /proc/loadavg)
    CPU_LOAD5=$(awk '{print $2}' /proc/loadavg)
    CPU_LOAD15=$(awk '{print $3}' /proc/loadavg)
    CPU_LOAD_STRING="Load: $CPU_LOAD1 (1m), $CPU_LOAD5 (5m), $CPU_LOAD15 (15m)"

    # Memory usage
    MEMORY=$(free -m | awk 'NR==2{printf "%s/%sMB (%.2f%%)", $3,$2,$3*100/$2}')

    # Disk usage
    DISK=$(df -h / | awk 'NR==2{printf "%s/%s (%s)", $3,$2,$5}')

    # Uptime
    UPTIME=$(cat /proc/uptime | cut -f1 -d.)
    UPTIME_DAYS=$((UPTIME/60/60/24))
    UPTIME_HOURS=$((UPTIME/60/60%24))
    UPTIME_MINS=$((UPTIME/60%60))
    UPTIME_SECSs=$((UPTIME%60))
    UPTIME_STRING="$((UPTIME_DAYS))d $((UPTIME_HOURS))h $((UPTIME_MINS))m"

    # IP Address
    IP_ADDRESS=$(hostname -I | awk '{print $1}')

    # Systemd Services
    SYSTEMD_SERVICES_FAILED=$(systemctl list-units --type=service --state=failed --no-legend | wc -l)

    # Output
    figlet "$(hostname)" | lolcat -f
    printf "$BOLD  * %-18s$ENDCOLOUR %s\n" "CPU" "$CPU_NAME, $CPU_CORES Cores"
    printf "$BOLD  * %-18s$ENDCOLOUR %s\n" "Load" "$CPU_LOAD_STRING"
    printf "$BOLD  * %-18s$ENDCOLOUR %s\n" "Release" "$PRETTY_NAME"
    printf "$BOLD  * %-18s$ENDCOLOUR %s\n" "Kernel" "$(uname -r)"
    printf "$BOLD  * %-18s$ENDCOLOUR %s\n" "Built" "$NIX_BUILD_TIME"
    printf "$BOLD  * %-18s$ENDCOLOUR %s\n" "Memory" "$MEMORY"
    printf "$BOLD  * %-18s$ENDCOLOUR %s\n" "Disk /" "$DISK"
    printf "$BOLD  * %-18s$ENDCOLOUR %s\n" "Uptime" "$UPTIME_STRING"
    printf "$BOLD  * %-18s$ENDCOLOUR %s\n" "IP" "$IP_ADDRESS"
    # Failed Services
    if [ "$SYSTEMD_SERVICES_FAILED" -eq 0 ]; then
      printf "$BOLD  * %-18s$ENDCOLOUR %s\n" "Failed Services" "None"
    else
      printf "$BOLD  * %-18s$ENDCOLOUR %s\n" "Failed Services" "$SYSTEMD_SERVICES_FAILED"
      while read -r line; do
        SERVICE_NAME=$(echo "$line" | awk '{print $1}' | sed 's/\.service$//')
        printf "$RED    x %s$ENDCOLOUR\n" "$SERVICE_NAME"
      done < <(systemctl list-units --type=service --state=failed --no-legend)
    fi
    printf "\n"
  '';
  cfg = config.modules.system.motd;
in
{
  options = {
    modules.system.motd = {
      enable = lib.mkEnableOption "MOTD" // {
        description = "Enable message of the day";
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ motd pkgs.figlet pkgs.lolcat ];
    programs.bash.interactiveShellInit = lib.mkIf config.programs.bash.enable ''
      motd
    '';
  };
}
