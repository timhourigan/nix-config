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
      if [ -z "$percent" ] || ! [[ "$percent" =~ ^[0-9]+$ ]]; then
        # Percentage is not valid, return white as default
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
        printf "0/0 (%s0%%%s)" "$WHITE" "$NOCOLOUR"
        return
      fi

      # Try to get disk usage info
      local usage_info
      usage_info=$(df -h "$mount_point" 2>/dev/null | awk 'NR==2{printf "%s|%s|%s", $3,$2,$5}')

      # Validate output (needs exactly 2 pipe delimiters)
      local pipe_count="''${usage_info//[^|]/}"
      if [ -z "$usage_info" ] || [ "''${#pipe_count}" -ne 2 ]; then
        printf "0/0 (%s0%%%s)" "$WHITE" "$NOCOLOUR"
        return
      fi

      local used
      used=$(echo "$usage_info" | cut -d'|' -f1)
      local total
      total=$(echo "$usage_info" | cut -d'|' -f2)
      local percent
      percent=$(echo "$usage_info" | cut -d'|' -f3 | tr -d '%')

      local colour
      colour=$(get_colour_by_percent "$percent")

      printf "%s/%s (%s%s%%%s)" "$used" "$total" "$colour" "$percent" "$NOCOLOUR"
    }

    # Memory Usage
    get_mem_usage() {
      local used
      used=$(free -m | awk 'NR==2{print $3}')
      local total
      total=$(free -m | awk 'NR==2{print $2}')
      local percent
      if [ "$total" -gt 0 ] 2>/dev/null; then
        percent=$((used * 100 / total))
      else
        percent=0
      fi

      local colour
      colour=$(get_colour_by_percent "$percent")

      printf "%s/%sMB (%s%s%%%s)" "$used" "$total" "$colour" "$percent" "$NOCOLOUR"
    }

    # ZFS Pool Status
    # Params: $1 - Pool name
    get_zpool_status() {
      local pool="$1"
      if ! zpool list "$pool" &>/dev/null; then
        printf "Not Found: %s" "$pool"
        return
      fi

      local pool_info
      pool_info=$(zpool list -Hpo name,size,alloc,health "$pool" 2>/dev/null)
      local total_bytes
      total_bytes=$(echo "$pool_info" | awk '{print $2}')
      local used_bytes
      used_bytes=$(echo "$pool_info" | awk '{print $3}')
      local health
      health=$(echo "$pool_info" | awk '{print $4}')

      local total_human
      total_human=$(numfmt --to=iec-i --suffix=B "$total_bytes")
      local used_human
      used_human=$(numfmt --to=iec-i --suffix=B "$used_bytes")

      local percent=0
      if [ "$total_bytes" -gt 0 ] 2>/dev/null; then
        percent=$((used_bytes * 100 / total_bytes))
      fi

      local health_colour="$GREEN"
      if [ "$health" != "ONLINE" ]; then
        health_colour="$RED"
      fi

      local colour
      colour=$(get_colour_by_percent "$percent")

      printf "%s/%s (%s%s%%%s) [%s%s%s]" "$used_human" "$total_human" "$colour" "$percent" "$NOCOLOUR" "$health_colour" "$health" "$NOCOLOUR"
    }

    # OS Information
    # shellcheck source=/dev/null
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

    # ZFS pool
    ZPOOL_STATUS=$(get_zpool_status zpool)

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
    if [ -n "$ZPOOL_STATUS" ]; then
      printf "$BOLD  * %-18s$NOCOLOUR %s\n" "ZFS zpool" "$ZPOOL_STATUS"
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
