{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/tailscale-serve.nix
    ./modules/docker.nix
  ];

  system.stateVersion = "26.05";
  networking.hostName = "app-node";
  # DHCP on all interfaces (incl. the virtio NIC) — matches hosts/media,
  # hosts/rocinante. Without this the fresh VM boots with no IP.
  networking.networkmanager.enable = true;

  # ── Firewall ─────────────────────────────────────────────────────────────
  # Tailscale handles external access (encrypted WireGuard tunnel).
  # Tailscale's virtual interface (tailscale0) is trusted — all other interfaces
  # block everything except SSH and k3s API. No ports are exposed to the internet.
  networking.firewall.enable = true;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  networking.firewall.allowedTCPPorts = [
    22    # SSH
    6443  # k3s API (accessed via Tailscale)
  ];
  networking.firewall.allowedUDPPorts = [ ];
  networking.firewall.allowPing = false;

  # ── Automatic updates ────────────────────────────────────────────────────
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
    dates = "04:00";
    persistent = true;
  };

  # ── fail2ban — protect SSH from brute force ─────────────────────────────
  # findtime defaults to 10m (upstream default, same as the original intent).
  services.fail2ban = {
    enable = true;
    maxretry = 3;
    bantime = "1h";
    ignoreIP = [
      "10.0.0.0/8"   # Proxmox LAN
      "100.64.0.0/10" # Tailscale
    ];
  };

  # fail2ban + NixOS firewall both use nftables — coordinated backend avoids conflicts
  networking.nftables.enable = true;

  # ── SSH ──────────────────────────────────────────────────────────────────
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      PubkeyAuthentication = true;
      MaxAuthTries = 3;
      MaxSessions = 3;
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;
    };
    startWhenNeeded = true;  # socket-activated, not always running
  };

  # ── User ─────────────────────────────────────────────────────────────────
  users.users.darren = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    # One-time bootstrap password — set your own with `passwd darren` after
    # first login (it prompts for this as the current password). Lives in git,
    # so rotate it before the VM does anything real.
    initialPassword = "xeoNyuiht3aJod";
    openssh.authorizedKeys.keys = [
      # Generate: ssh-keygen -t ed25519 -C "home-k8s" -f ~/.ssh/home-k8s
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAhq0+ALrOXHLNC/75PGi9ymM/nHfCgS5Wc0yUoRTfEP home-k8s"
    ];
  };

  security.sudo.extraRules = [ ];

  # Make the k3s admin kubeconfig world-readable (root-only by default) so
  # the plain `kubectl` package works for all users without sudo. Runs once
  # after k3s starts; idempotent.
  systemd.services.make-k3s-kubeconfig-readable = {
    description = "Make k3s admin kubeconfig readable by all users";
    after = [ "k3s.service" ];
    wants = [ "k3s.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      KUBECONFIG=/etc/rancher/k3s/k3s.yaml
      if [ -f "$KUBECONFIG" ]; then
        chmod 644 "$KUBECONFIG"
        # Also expose for the user's ~/.kube/config (kubectl's default lookup)
        mkdir -p /home/darren/.kube
        cp "$KUBECONFIG" /home/darren/.kube/config
        chown -R darren:users /home/darren/.kube
        chmod 600 /home/darren/.kube/config
      fi
    '';
  };

  #####################################################################
  # SERVICES
  ####################################################################

  # ─ k3s ────────────────────────────────────────────────────────────────
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = [
      "--disable=traefik"
      "--disable=servicelb"
      # Bind the k8s control-plane components to loopback, never the network
      "--kube-controller-manager-arg" "bind-address=127.0.0.1"
      "--kube-scheduler-arg" "bind-address=127.0.0.1"
    ];
  };

  # ── Tailscale ──────────────────────────────────────────────────────────
  services.tailscale.enable = true;

  # ── Tailscale Serve (custom module) ─────────────────────────────────────
  services.tailscale-serve = {
    enable = true;
    port = 80;
    target = "127.0.0.1:8080";
  };

  # ── Docker ──────────────────────────────────────────────────────────────
  virtualisation.docker.enable = true;

  # ── System health check ─────────────────────────────────────────────────
  systemd.services.healthcheck = {
    description = "System health check — disk, memory, services";
    script = ''
      LOG=/var/log/health/health.log
      mkdir -p /var/log/health
      DISK=$(${pkgs.coreutils}/bin/df / | ${pkgs.gawk}/bin/awk 'NR==2 {print $5}' | ${pkgs.coreutils}/bin/tr -d '%')
      RAM=$(${pkgs.procps}/bin/free | ${pkgs.gawk}/bin/awk '/Mem:/ {printf "%.0f", $3/$2*100}')
      NOW=$(${pkgs.coreutils}/bin/date -Iseconds)
      [ "$DISK" -gt 90 ] && echo "$NOW ALERT Disk ''${DISK}%" >> "$LOG"
      [ "$RAM" -gt 90 ] && echo "$NOW ALERT RAM ''${RAM}%" >> "$LOG"
      ${pkgs.systemd}/bin/systemctl is-active --quiet k3s || echo "$NOW ALERT k3s DOWN" >> "$LOG"
      [ -f /var/run/reboot-required ] && echo "$NOW WARN reboot pending" >> "$LOG"
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  systemd.timers.healthcheck = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/5";
      Persistent = true;
    };
  };

  # ── Directory layout ────────────────────────────────────────────────────
  systemd.tmpfiles.rules = [
    "d /opt/nix-config/manifests 0755 root root -"
    "d /opt/nix-config/secrets 0700 root root -"
    "d /var/backups/app 0755 root root -"
    "d /var/log/health 0755 root root -"
  ];

  # ── Kernel hardening ─────────────────────────────────────────────────────
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "kernel.sysrq" = 0;
  };

  # ── Build tooling ───────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    git
    curl
    openssl
    jq
    vim
    k9s
    kubectl
    k3s      # CLI used by scripts/build-app.sh (`k3s ctr images import`)
    sops
    age
    htop
  ];
}