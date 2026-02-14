{ lib, config, pkgs, ... }:

let
  motd = pkgs.writeShellScriptBin "motd" ''
    # Colours and formatting
    RED=$'\e[31m'
    ORANGE=$'\e[33m'
    GREEN=$'\e[32m'
    WHITE=$'\e[37m'
    BOLD=$'\e[1m'
    NOCOLOUR=$'\e[0m'

    # Colour by percentage
    # Params: $1 - Percentage value
    get_colour_by_percent() {
      local percent="$1"
      # Validate that percent is a non-empty numeric value
      if [ -z "$percent" ] || ! [[ "$percent" =~ ^[0-9]+$ ]]; then
        echo "$WHITE"
        return
      fi
      if [ "$percent" -ge 90 ]; then
        echo "$RED"
      elif [ "$percent" -ge 75 ]; then
        echo "$ORANGE"
      else
        echo "$GREEN"
      fi
    }

    # Disk Usage
    # Params: $1 - Mount point
    get_disk_usage() {
      local mount_point="$1"
      
      # Check if mount point exists and is a directory
      if [ ! -d "$mount_point" ]; then
        printf "N/A"
        return
      fi
      
      # Try to get disk usage info, redirecting errors
      local usage_info=$(df -h "$mount_point" 2>/dev/null | awk 'NR==2{printf "%s|%s|%s", $3,$2,$5}')
      
      # Check if df command succeeded and returned valid data (needs at least 2 pipe delimiters)
      local pipe_count="${usage_info//[^|]/}"
      if [ -z "$usage_info" ] || [ "${#pipe_count}" -lt 2 ]; then
        printf "N/A"
        return
      fi
      
      local used=$(echo "$usage_info" | cut -d'|' -f1)
      local total=$(echo "$usage_info" | cut -d'|' -f2)
      local percent=$(echo "$usage_info" | cut -d'|' -f3 | tr -d '%')

      local colour=$(get_colour_by_percent "$percent")

      printf "%s/%s (%s%s%%%s)" "$used" "$total" "$colour" "$percent" "$NOCOLOUR"
    }

    # Memory Usage
    get_mem_usage() {
      local used=$(free -m | awk 'NR==2{print $3}')
      local total=$(free -m | awk 'NR==2{print $2}')
      local percent
      if [ "$total" -gt 0 ] 2>/dev/null; then
        percent=$((used * 100 / total))
      else
        percent=0
      fi

      local colour=$(get_colour_by_percent "$percent")

      printf "%s/%sMB (%s%s%%%s)" "$used" "$total" "$colour" "$percent" "$NOCOLOUR"
    }

    # OS Information
    source /etc/os-release
    NIX_BUILD_TIME=$(stat -c %y /run/current-system | cut -d. -f1)

    # CPU
    CPU_NAME=$(awk -F': ' '/model name/ {print $2; exit}' /proc/cpuinfo)
    CPU_CORES=$(nproc)
    CPU_LOAD1=$(awk '{print $1}' /proc/loadavg)
    CPU_LOAD5=$(awk '{print $2}' /proc/loadavg)
    CPU_LOAD15=$(awk '{print $3}' /proc/loadavg)
    CPU_LOAD_STRING="$CPU_LOAD1 (1m), $CPU_LOAD5 (5m), $CPU_LOAD15 (15m)"

    # Memory usage
    MEMORY=$(get_mem_usage)

    # Disk usage
    DISK_ROOT=$(get_disk_usage /)
    if [ -d /mnt/backup ]; then
      DISK_BACKUP=$(get_disk_usage /mnt/backup)
    fi

    # Uptime
    UPTIME=$(cat /proc/uptime | cut -f1 -d.)
    UPTIME_DAYS=$((UPTIME/60/60/24))
    UPTIME_HOURS=$((UPTIME/60/60%24))
    UPTIME_MINS=$((UPTIME/60%60))
    UPTIME_STRING="$((UPTIME_DAYS))d $((UPTIME_HOURS))h $((UPTIME_MINS))m"

    # IP Address
    IP_ADDRESS=$(hostname -I | awk '{print $1}')

    # Systemd Services
    SYSTEMD_SERVICES_FAILED=$(systemctl list-units --type=service --state=failed --no-legend | wc -l)

    # Output
    figlet "$(hostname)" | lolcat -f
    printf "$BOLD  * %-18s$NOCOLOUR %s\n" "CPU" "$CPU_NAME, $CPU_CORES Cores"
    printf "$BOLD  * %-18s$NOCOLOUR %s\n" "Release" "$PRETTY_NAME"
    printf "$BOLD  * %-18s$NOCOLOUR %s\n" "Kernel" "$(uname -r)"
    printf "$BOLD  * %-18s$NOCOLOUR %s\n" "Built" "$NIX_BUILD_TIME"
    printf "\n"
    printf "$BOLD  * %-18s$NOCOLOUR %s\n" "Uptime" "$UPTIME_STRING"
    printf "$BOLD  * %-18s$NOCOLOUR %s\n" "IP" "$IP_ADDRESS"
    printf "\n"
    printf "$BOLD  * %-18s$NOCOLOUR %s\n" "Load" "$CPU_LOAD_STRING"
    printf "$BOLD  * %-18s$NOCOLOUR %s\n" "Memory" "$MEMORY"
    printf "$BOLD  * %-18s$NOCOLOUR %s\n" "Disk /" "$DISK_ROOT"
    if [ -n "$DISK_BACKUP" ]; then
      printf "$BOLD  * %-18s$NOCOLOUR %s\n" "Disk /mnt/backup" "$DISK_BACKUP"
    fi
    printf "\n"
    # Failed Services
    if [ "$SYSTEMD_SERVICES_FAILED" -eq 0 ]; then
      printf "$BOLD  * %-18s$NOCOLOUR %s\n" "Failed Services" "None"
    else
      printf "$BOLD  * %-18s$NOCOLOUR %s\n" "Failed Services" "$SYSTEMD_SERVICES_FAILED"
      while read -r line; do
        SERVICE_NAME=$(echo "$line" | awk '{print $1}' | sed 's/\.service$//')
        printf "$RED    x %s$NOCOLOUR\n" "$SERVICE_NAME"
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
