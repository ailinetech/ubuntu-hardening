#!/bin/bash
# ============================================================
#
#   ░█████╗░██╗    ██╗     ██╗███╗   ██╗███████╗
#   ██╔══██╗██║    ██║     ██║████╗  ██║██╔════╝
#   ███████║██║    ██║     ██║██╔██╗ ██║█████╗
#   ██╔══██║██║    ██║     ██║██║╚██╗██║██╔══╝
#   ██║  ██║██║    ███████╗██║██║ ╚████║███████╗
#   ╚═╝  ╚═╝╚═╝    ╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝
#
#   Ai Line Tech — Cloud & Security Enterprise Toolkit
# ============================================================
#  Product : Ubuntu Auto Hardening Script
#  Target  : Ubuntu 20.04 / 22.04 / 24.04 LTS (Fresh Install)
#  Author  : Ai Line Tech (https://ailinetech.com)
#  License : Open Source — Free to use, Premium Support available
#  Version : 1.0.0
#  Usage   : sudo bash ubuntu-hardening.sh
# ------------------------------------------------------------
#  Copyright (c) 2025 Ai Line Tech. All rights reserved.
#  Redistribution permitted with attribution.
#  Commercial support: support@ailinetech.com
# ============================================================

set -euo pipefail

# ─── Colours ────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

# ─── Helpers ────────────────────────────────────────────────
info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()      { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()     { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
section() { echo -e "\n${BOLD}${BLUE}══════════════════════════════════════${NC}"; \
            echo -e "${BOLD}${BLUE}  $*${NC}"; \
            echo -e "${BOLD}${BLUE}══════════════════════════════════════${NC}"; }

# ─── Root check ─────────────────────────────────────────────
[[ $EUID -ne 0 ]] && err "Script harus dijalankan sebagai root: sudo bash $0"

# ─── Detect Ubuntu version ──────────────────────────────────
UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "unknown")
HOSTNAME_FQDN=$(hostname -f 2>/dev/null || hostname)

# ─── Log file ───────────────────────────────────────────────
LOGFILE="/var/log/hardening-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOGFILE") 2>&1
info "Log disimpan di: $LOGFILE"

echo -e "${BOLD}${CYAN}"
cat <<'AILINE_BANNER'

    ___  _   _     _     _            _____         _
   / _ \(_) | |   (_)   (_)          |_   _|       | |
  / /_\ \ | | |    _ _ __   ___         | | ___  ___| |__
  |  _  | || |   | | '_ \ / _ \        | |/ _ \/ __| '_ \
  | | | | || |___| | | | |  __/        | |  __/ (__| | | |
  \_| |_/_||_____|_|_| |_|\___|        \_/\___|___|_| |_|

  Ai Line Tech — Cloud & Security Enterprise Toolkit
  Ubuntu Auto Hardening Script v1.0.0
  Copyright (c) 2025 Ai Line Tech — https://ailinetech.com
  Open Source | Premium Support: support@ailinetech.com

AILINE_BANNER
echo -e "${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
info "Ubuntu $UBUNTU_VERSION  |  Host: $HOSTNAME_FQDN  |  $(date)"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# ============================================================
# 1. UPDATE & UPGRADE SYSTEM
# ============================================================
section "1. Update & Upgrade System"

apt-get update -qq
apt-get upgrade -y -qq
apt-get dist-upgrade -y -qq
apt-get autoremove -y -qq
apt-get autoclean -qq
ok "System updated"

# ============================================================
# 2. INSTALL ESSENTIAL TOOLS
# ============================================================
section "2. Install Essential Security Tools"

PACKAGES=(
    ufw fail2ban unattended-upgrades
    auditd audispd-plugins
    rkhunter chkrootkit
    apparmor apparmor-utils
    libpam-pwquality
    aide
    curl wget git vim net-tools
    htop iotop
    logwatch
    acct           # process accounting
    sysstat        # system statistics
    needrestart    # notify outdated services
)

apt-get install -y -qq "${PACKAGES[@]}" && ok "Packages installed" || warn "Beberapa paket gagal diinstall, lanjutkan..."

# ============================================================
# 3. AUTOMATIC SECURITY UPDATES
# ============================================================
section "3. Konfigurasi Automatic Security Updates"

cat > /etc/apt/apt.conf.d/50unattended-upgrades <<'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};
Unattended-Upgrade::Package-Blacklist {};
Unattended-Upgrade::DevRelease "false";
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Mail "root";
EOF

cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

systemctl enable unattended-upgrades --quiet
systemctl restart unattended-upgrades
ok "Auto security updates dikonfigurasi"

# ============================================================
# 4. FIREWALL (UFW)
# ============================================================
section "4. Konfigurasi Firewall UFW"

ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw default deny forward

# Allow SSH (ubah port jika perlu)
SSH_PORT="${SSH_PORT:-22}"
ufw allow "${SSH_PORT}/tcp" comment 'SSH'

ufw logging on
ufw --force enable
ok "Firewall UFW aktif — hanya port SSH ($SSH_PORT) yang dibuka"
info "Tambahkan port lain secara manual: ufw allow <port>/tcp"

# ============================================================
# 5. SSH HARDENING
# ============================================================
section "5. Hardening SSH"

SSHD_CONFIG="/etc/ssh/sshd_config"
cp "$SSHD_CONFIG" "${SSHD_CONFIG}.bak.$(date +%Y%m%d)"

# Buat konfigurasi SSH yang aman
cat > /etc/ssh/sshd_config.d/99-hardening.conf <<EOF
# ── SSH Hardening by ubuntu-hardening.sh ──────────────────
Port ${SSH_PORT}
Protocol 2

# Autentikasi
PermitRootLogin no
MaxAuthTries 3
MaxSessions 5
LoginGraceTime 30
PasswordAuthentication yes       # Ganti ke 'no' jika sudah pakai SSH key
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

# Keamanan tambahan
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitUserEnvironment no
Compression no
ClientAliveInterval 300
ClientAliveCountMax 2
TCPKeepAlive no
UseDNS no
PrintMotd no
Banner /etc/issue.net

# Algoritma kriptografi kuat (modern)
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group14-sha256,diffie-hellman-group16-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com
EOF

# Banner peringatan
cat > /etc/issue.net <<'EOF'
***************************************************************************
                        SISTEM INI DIPANTAU
   Akses tidak sah dilarang. Semua aktivitas dicatat dan dipantau.
   Penggunaan sistem ini berarti persetujuan terhadap kebijakan keamanan.
***************************************************************************
EOF

sshd -t && systemctl restart sshd && ok "SSH hardening selesai" || warn "Konfigurasi SSH ada masalah, periksa manual"

# ============================================================
# 6. FAIL2BAN
# ============================================================
section "6. Konfigurasi Fail2Ban"

cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime  = 3600
findtime = 600
maxretry = 5
backend  = systemd
banaction = ufw

[sshd]
enabled  = true
port     = ${SSH_PORT}
logpath  = %(sshd_log)s
maxretry = 3
bantime  = 86400

[sshd-ddos]
enabled  = true
port     = ${SSH_PORT}
logpath  = %(sshd_log)s
maxretry = 10
findtime = 30
bantime  = 3600
EOF

systemctl enable fail2ban --quiet
systemctl restart fail2ban
ok "Fail2Ban aktif — SSH brute-force dilindungi"

# ============================================================
# 7. KERNEL / SYSCTL HARDENING
# ============================================================
section "7. Kernel & Network Hardening (sysctl)"

cat > /etc/sysctl.d/99-hardening.conf <<'EOF'
# ── Kernel Hardening ─────────────────────────────────────

# Sembunyikan informasi kernel
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.perf_event_paranoid = 3
kernel.sysrq = 0
kernel.core_uses_pid = 1
kernel.randomize_va_space = 2

# Lindungi symlink & hardlink
fs.protected_symlinks = 1
fs.protected_hardlinks = 1
fs.protected_fifos = 2
fs.protected_regular = 2
fs.suid_dumpable = 0

# ── Network Hardening ────────────────────────────────────

# Nonaktifkan IP forwarding (aktifkan jika router/VPN)
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# Lindungi terhadap spoofing & ICMP attacks
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0

# Lindungi SYN flood
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# Nonaktifkan ping broadcast & log paket aneh
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# IPv6 hardening
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0
net.ipv6.conf.all.autoconf = 0

# TCP hardening
net.ipv4.tcp_rfc1337 = 1
net.ipv4.tcp_timestamps = 0
EOF

sysctl -p /etc/sysctl.d/99-hardening.conf --quiet
ok "Kernel & network parameters diterapkan"

# ============================================================
# 8. PASSWORD POLICY
# ============================================================
section "8. Kebijakan Password"

# PAM pwquality
cat > /etc/security/pwquality.conf <<'EOF'
minlen = 12
dcredit = -1
ucredit = -1
ocredit = -1
lcredit = -1
maxrepeat = 3
maxsequence = 4
gecoscheck = 1
badwords = password passwd ubuntu linux
enforce_for_root
EOF

# Login defs
sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/'  /etc/login.defs
sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   7/'   /etc/login.defs
sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   14/'  /etc/login.defs

# Kunci akun setelah gagal login
if grep -q "pam_tally2" /etc/pam.d/common-auth 2>/dev/null; then
    :
elif command -v faillock &>/dev/null; then
    # Ubuntu 22.04+ menggunakan faillock
    grep -q "pam_faillock" /etc/pam.d/common-auth || \
    sed -i '/pam_unix.so/i auth required pam_faillock.so preauth silent deny=5 unlock_time=900 fail_interval=900' \
        /etc/pam.d/common-auth
fi

ok "Kebijakan password diterapkan (min 12 karakter, max 90 hari)"

# ============================================================
# 9. USER & SUDO HARDENING
# ============================================================
section "9. User & Sudo Hardening"

# Nonaktifkan akun tidak perlu
for USER in games gnats irc list news sync uucp; do
    usermod -s /usr/sbin/nologin "$USER" 2>/dev/null || true
done

# Sudo: log semua perintah, timeout singkat
cat > /etc/sudoers.d/99-hardening <<'EOF'
# Catat semua perintah sudo
Defaults log_output
Defaults!/usr/bin/sudoreplay !log_output
Defaults logfile="/var/log/sudo.log"

# Timeout session sudo: 5 menit
Defaults timestamp_timeout=5

# Wajib password meski sudah cache
Defaults !visiblepw

# Batasi env yang diwariskan
Defaults env_reset
Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
EOF

chmod 440 /etc/sudoers.d/99-hardening
ok "Sudo dikonfigurasi dengan logging dan timeout"

# ============================================================
# 10. FILESYSTEM HARDENING
# ============================================================
section "10. Filesystem Hardening"

# Amankan /tmp dengan tmpfs
if ! grep -q "^tmpfs /tmp" /etc/fstab; then
    echo "tmpfs /tmp tmpfs rw,nosuid,nodev,noexec,relatime,size=1G 0 0" >> /etc/fstab
    mount -o remount /tmp 2>/dev/null || warn "/tmp akan aman setelah reboot"
    ok "/tmp dikonfigurasi: nosuid,nodev,noexec"
fi

# Amankan /dev/shm
if grep -q "^tmpfs /dev/shm" /etc/fstab; then
    sed -i 's|^tmpfs /dev/shm.*|tmpfs /dev/shm tmpfs rw,nosuid,nodev,noexec 0 0|' /etc/fstab
else
    echo "tmpfs /dev/shm tmpfs rw,nosuid,nodev,noexec 0 0" >> /etc/fstab
fi
mount -o remount /dev/shm 2>/dev/null || true

# Batasi permission direktori home
chmod 750 /root
chmod 711 /home

# Hapus SUID bit yang tidak perlu
SUID_REMOVE=(
    /usr/bin/at
    /usr/bin/wall
    /usr/bin/write
    /usr/sbin/pppd
    /usr/bin/newgrp
)
for f in "${SUID_REMOVE[@]}"; do
    [[ -f "$f" ]] && chmod a-s "$f" && info "SUID dihapus: $f"
done

ok "Filesystem hardening selesai"

# ============================================================
# 11. AUDIT (auditd)
# ============================================================
section "11. Konfigurasi Audit Daemon"

cat > /etc/audit/rules.d/99-hardening.rules <<'EOF'
# Hapus semua rule lama
-D

# Buffer size
-b 8192

# Failure mode: 1=log, 2=panic
-f 1

# ── Monitor file kritis ──────────────────────────────────
-w /etc/passwd -p wa -k passwd_changes
-w /etc/shadow -p wa -k shadow_changes
-w /etc/group  -p wa -k group_changes
-w /etc/gshadow -p wa -k gshadow_changes
-w /etc/sudoers -p wa -k sudoers_changes
-w /etc/sudoers.d/ -p wa -k sudoers_changes
-w /etc/ssh/sshd_config -p wa -k sshd_config
-w /etc/hosts -p wa -k hosts_changes

# ── Monitor autentikasi ──────────────────────────────────
-w /var/log/auth.log -p wa -k auth_log
-w /var/log/faillog -p wa -k faillog
-w /var/log/lastlog -p wa -k lastlog
-w /bin/login -p x -k login
-w /bin/su -p x -k su

# ── Monitor perubahan jaringan ───────────────────────────
-a always,exit -F arch=b64 -S sethostname -S setdomainname -k network_changes
-w /etc/network/ -p wa -k network_changes
-w /etc/hosts -p wa -k network_changes

# ── Deteksi eksekusi mencurigakan ───────────────────────
-a always,exit -F arch=b64 -S execve -F euid=0 -F auid!=4294967295 -k root_exec
-w /tmp -p x -k tmp_exec
-w /dev/shm -p x -k shm_exec

# ── Monitor crontab ─────────────────────────────────────
-w /etc/cron.d/ -p wa -k cron
-w /etc/crontab -p wa -k cron
-w /var/spool/cron/ -p wa -k cron

# ── Monitor kernel module ────────────────────────────────
-w /sbin/insmod -p x -k modules
-w /sbin/rmmod -p x -k modules
-w /sbin/modprobe -p x -k modules
-a always,exit -F arch=b64 -S init_module -S delete_module -k modules

# ── Kunci rules (immutable setelah boot) ─────────────────
-e 2
EOF

augenrules --load 2>/dev/null || auditctl -R /etc/audit/rules.d/99-hardening.rules 2>/dev/null || true
systemctl enable auditd --quiet
systemctl restart auditd
ok "Audit daemon aktif dengan rules lengkap"

# ============================================================
# 12. APPARMOR
# ============================================================
section "12. AppArmor"

systemctl enable apparmor --quiet
systemctl start apparmor
aa-enforce /etc/apparmor.d/* 2>/dev/null || true
ok "AppArmor aktif (enforce mode)"

# ============================================================
# 13. DISABLE UNUSED SERVICES & PROTOCOLS
# ============================================================
section "13. Nonaktifkan Layanan & Protokol Tidak Perlu"

DISABLE_SERVICES=(
    avahi-daemon
    cups
    isc-dhcp-server
    isc-dhcp-server6
    rpcbind
    nfs-server
    nis
    tftp
    xinetd
    telnet
    rsh-server
    talk
    snmpd
)

for svc in "${DISABLE_SERVICES[@]}"; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        systemctl stop "$svc" 2>/dev/null
        systemctl disable "$svc" 2>/dev/null
        info "Dinonaktifkan: $svc"
    fi
done

# Nonaktifkan protokol jaringan tidak perlu
cat > /etc/modprobe.d/disable-protocols.conf <<'EOF'
install dccp /bin/true
install sctp /bin/true
install rds /bin/true
install tipc /bin/true
install n-hdlc /bin/true
install ax25 /bin/true
install netrom /bin/true
install x25 /bin/true
install rose /bin/true
install decnet /bin/true
install econet /bin/true
install af_802154 /bin/true
install ipx /bin/true
install appletalk /bin/true
install psnap /bin/true
install p8023 /bin/true
install llc /bin/true
install p8022 /bin/true
EOF

# Nonaktifkan filesystem tidak perlu
cat > /etc/modprobe.d/disable-filesystems.conf <<'EOF'
install cramfs /bin/true
install freevxfs /bin/true
install jffs2 /bin/true
install hfs /bin/true
install hfsplus /bin/true
install squashfs /bin/true
install udf /bin/true
EOF

ok "Layanan dan protokol tidak perlu dinonaktifkan"

# ============================================================
# 14. RKHUNTER
# ============================================================
section "14. RKHunter Setup"

rkhunter --update --nocolors 2>/dev/null || true
rkhunter --propupd --nocolors 2>/dev/null || true

# Jadwalkan scan harian
cat > /etc/cron.daily/rkhunter-scan <<'EOF'
#!/bin/bash
/usr/bin/rkhunter --cronjob --update --quiet --nocolors \
    --report-warnings-only 2>&1 | mail -s "RKHunter Report $(hostname) $(date +%Y-%m-%d)" root
EOF
chmod +x /etc/cron.daily/rkhunter-scan
ok "RKHunter diperbarui dan dijadwalkan harian"

# ============================================================
# 15. AIDE (File Integrity Monitoring)
# ============================================================
section "15. AIDE - File Integrity Monitoring"

aide --init --config /etc/aide/aide.conf 2>/dev/null && \
    mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db 2>/dev/null && \
    ok "AIDE database diinisialisasi" || \
    warn "AIDE init gagal, jalankan manual: aide --init setelah instalasi selesai"

# Jadwalkan check harian
cat > /etc/cron.daily/aide-check <<'EOF'
#!/bin/bash
/usr/bin/aide --check --config /etc/aide/aide.conf 2>&1 | \
    mail -s "AIDE Report $(hostname) $(date +%Y-%m-%d)" root
EOF
chmod +x /etc/cron.daily/aide-check

# ============================================================
# 16. LOG HARDENING
# ============================================================
section "16. Log Hardening"

# Amankan permission log
chmod 640 /var/log/auth.log 2>/dev/null || true
chmod 640 /var/log/syslog 2>/dev/null || true

# Konfigurasi logrotate
cat > /etc/logrotate.d/hardening-logs <<'EOF'
/var/log/sudo.log {
    weekly
    rotate 52
    compress
    delaycompress
    missingok
    notifempty
    create 640 root adm
}
EOF

# Aktifkan logging boot
if ! grep -q "GRUB_CMDLINE_LINUX.*audit=1" /etc/default/grub 2>/dev/null; then
    sed -i 's/GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="\1 audit=1 audit_backlog_limit=8192"/' \
        /etc/default/grub 2>/dev/null || true
    update-grub 2>/dev/null || true
fi

ok "Log hardening selesai"

# ============================================================
# 17. MOTD (Message of the Day)
# ============================================================
section "17. Konfigurasi MOTD"

# Nonaktifkan MOTD default Ubuntu yang berlebihan
chmod -x /etc/update-motd.d/10-help-text 2>/dev/null || true
chmod -x /etc/update-motd.d/50-motd-news 2>/dev/null || true
chmod -x /etc/update-motd.d/80-esm-announce 2>/dev/null || true

cat > /etc/motd <<'EOF'

  ___  _   _     _     _            _____         _
 / _ \(_) | |   (_)   (_)          |_   _|       | |
/ /_\ \ | | |    _ _ __   ___       | | ___  ___| |__
|  _  | || |   | | '_ \ / _ \      | |/ _ \/ __| '_ \
| | | | || |___| | | | |  __/      | |  __/ (__| | | |
\_| |_/_||_____|_|_| |_|\___|      \_/\___|___|_| |_|

  Cloud & Security Enterprise Toolkit v1.0.0
  Secured by Ai Line Tech — https://ailinetech.com

  SISTEM INI TELAH DI-HARDENING & DIPANTAU
  Semua aktivitas dicatat. Akses tidak sah melanggar hukum.
  Butuh bantuan? support@ailinetech.com

EOF

ok "MOTD dikonfigurasi"

# ============================================================
# SUMMARY & CHECKLIST
# ============================================================
section "HARDENING SELESAI - RINGKASAN"

echo -e "${GREEN}"
cat <<'EOF'
 ✔  System update & upgrade
 ✔  Automatic security updates
 ✔  Firewall UFW (default deny incoming)
 ✔  SSH hardening (no root login, strong ciphers)
 ✔  Fail2Ban (brute-force protection)
 ✔  Kernel & sysctl hardening
 ✔  Password policy (min 12 char, max 90 hari)
 ✔  User & sudo hardening dengan logging
 ✔  Filesystem: /tmp & /dev/shm nosuid,nodev,noexec
 ✔  SUID bits dibersihkan
 ✔  Audit daemon (auditd) dengan rules lengkap
 ✔  AppArmor (enforce mode)
 ✔  Layanan tidak perlu dinonaktifkan
 ✔  Protokol jaringan berbahaya diblokir
 ✔  RKHunter (rootkit scanner, jadwal harian)
 ✔  AIDE (file integrity monitoring)
 ✔  Log hardening & logrotate
EOF
echo -e "${NC}"

echo -e "${YELLOW}"
cat <<'EOF'
 ⚠  TINDAKAN MANUAL YANG DISARANKAN:
    1. Buat SSH key dan set PasswordAuthentication no di sshd_config.d/99-hardening.conf
    2. Tambahkan user ke grup sudo dengan: usermod -aG sudo <username>
    3. Buka port tambahan yang diperlukan: ufw allow <port>/tcp
    4. Review /var/log/hardening-*.log untuk detail
    5. Reboot sistem untuk menerapkan semua perubahan kernel
    6. Verifikasi AIDE: aide --check
    7. Cek status: ufw status verbose && fail2ban-client status sshd
EOF
echo -e "${NC}"

echo ""
info "Log lengkap: $LOGFILE"
echo ""
echo -e "${BOLD}${GREEN}Hardening selesai pada: $(date)${NC}"
echo -e "${CYAN}Powered by Ai Line Tech — Cloud & Security Enterprise Toolkit${NC}"
echo -e "${CYAN}Support  : support@ailinetech.com${NC}"
echo -e "${CYAN}Website  : https://ailinetech.com${NC}"
echo -e "${BOLD}${YELLOW}Disarankan untuk REBOOT sekarang: sudo reboot${NC}"
echo ""
