# 🔧 Ubuntu Auto Hardening Script

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0-00d4ff?style=for-the-badge)
![License](https://img.shields.io/badge/license-MIT-00ff88?style=for-the-badge)
![Platform](https://img.shields.io/badge/platform-Ubuntu%2020%2F22%2F24%20LTS-orange?style=for-the-badge)
![Standard](https://img.shields.io/badge/standard-CIS%20Benchmark-blue?style=for-the-badge)

**Ai Line Tech — Cloud & Security Enterprise Toolkit**

*Amankan server Ubuntu dalam ~5 menit. 17 modul hardening. Satu perintah.*

[🌐 Website](https://ailinetech.com) · [📧 Support](mailto:support@ailinetech.com) · [📋 Dokumentasi](#dokumentasi) · [🐛 Report Bug](https://github.com/ailinetech/ubuntu-hardening/issues)

</div>

---

## ✨ Tentang

`ubuntu-hardening.sh` adalah skrip bash otomatis yang menerapkan **17 modul hardening keamanan** pada Ubuntu fresh install — mengikuti standar **CIS Benchmark**, **NIST SP 800-53**, dan best practice sysadmin Linux.

```bash
sudo bash ubuntu-hardening.sh
```

Selesai. Server Anda langsung terlindungi.

---

## 🚀 Quick Start

```bash
# Clone repository
git clone https://github.com/ailinetech/ubuntu-hardening.git
cd ubuntu-hardening

# Beri izin eksekusi
chmod +x ubuntu-hardening.sh

# Jalankan sebagai root
sudo bash ubuntu-hardening.sh

# Opsional: custom port SSH
sudo SSH_PORT=2222 bash ubuntu-hardening.sh
```

---

## 📋 17 Modul yang Diterapkan

| # | Modul | Keterangan |
|---|-------|-----------|
| 01 | 🔄 **System Update** | Full upgrade + autoremove |
| 02 | 🛠️ **Install Tools** | UFW, fail2ban, auditd, rkhunter, aide, apparmor |
| 03 | 📡 **Auto Updates** | unattended-upgrades harian otomatis |
| 04 | 🔥 **Firewall UFW** | Default deny incoming, hanya SSH terbuka |
| 05 | 🔐 **SSH Hardening** | No root login, strong ciphers, MaxAuthTries=3 |
| 06 | 🛡️ **Fail2Ban** | Block IP setelah 3x gagal login, 24 jam |
| 07 | ⚙️ **Kernel Sysctl** | 40+ parameter: anti-spoofing, SYN flood, ICMP |
| 08 | 🔑 **Password Policy** | Min 12 karakter, max 90 hari, kompleksitas wajib |
| 09 | 👤 **Sudo Hardening** | Log semua perintah, timeout 5 menit |
| 10 | 💾 **Filesystem** | /tmp & /dev/shm nosuid/nodev/noexec |
| 11 | 📋 **Auditd Rules** | Monitor passwd, shadow, sudoers, sshd_config |
| 12 | 🔒 **AppArmor** | Enforce mode semua profil |
| 13 | 🚫 **Disable Services** | Nonaktifkan avahi, cups, rpcbind, nfs, telnet |
| 14 | 🔍 **RKHunter** | Rootkit scanner, jadwal cron harian |
| 15 | 🗂️ **AIDE** | File integrity monitoring database |
| 16 | 📝 **Log Hardening** | Permission log, logrotate, audit boot |
| 17 | ⚠️ **MOTD & Banner** | Banner peringatan keamanan saat login |

---

## 🖥️ Kompatibilitas

| OS | Status |
|----|--------|
| Ubuntu 20.04 LTS (Focal Fossa) | ✅ Didukung |
| Ubuntu 22.04 LTS (Jammy Jellyfish) | ✅ Didukung |
| Ubuntu 24.04 LTS (Noble Numbat) | ✅ Didukung |
| Debian 11/12 | ⚠️ Sebagian besar berjalan |

---

## 📖 Dokumentasi

### Prasyarat

- Ubuntu fresh install (recommended)
- Akses root / sudo
- Koneksi internet aktif
- Minimal 1 GB disk space kosong

### Langkah Manual Setelah Hardening

1. **Buat SSH Key** dan set `PasswordAuthentication no`
2. **Reboot** — wajib agar semua perubahan kernel aktif
3. **Buka port tambahan** sesuai kebutuhan: `ufw allow 80/tcp`
4. **Verifikasi**: `ufw status verbose && fail2ban-client status sshd`

### Verifikasi

```bash
# Cek status firewall
sudo ufw status verbose

# Cek Fail2Ban
sudo fail2ban-client status sshd

# Cek AppArmor
sudo aa-status

# Lihat log hardening
cat /var/log/hardening-*.log
```

---

## 📊 Skor Keamanan

Setelah menjalankan script ini, gunakan **Ai Line Tech Security Scanner** untuk memverifikasi:

```bash
# Install Security Scanner
sudo bash install-scanner.sh

# Scan server Anda
sudo ailine-scanner --client
```

Server yang baru di-hardening biasanya mendapat **Grade A (90-100)**.

---

## 🤝 Kontribusi

Pull request dan issue sangat diterima! Pastikan Anda mengikuti panduan kontribusi.

```bash
# Fork repository
git fork https://github.com/ailinetech/ubuntu-hardening

# Buat branch baru
git checkout -b feat/nama-fitur

# Commit dan push
git commit -m "feat: deskripsi fitur"
git push origin feat/nama-fitur
```

---

## 📦 Produk Lain dari Ai Line Tech

| Produk | Deskripsi |
|--------|-----------|
| [🛡️ WAF Toolkit](https://github.com/ailinetech/waf-toolkit) | ModSecurity + Nginx Lua + Fail2Ban |
| [📊 Security Scanner](https://github.com/ailinetech/security-scanner) | Audit 32+ checks, Grade A-F, PDF otomatis |
| [🔬 Malware Scanner](https://github.com/ailinetech/malware-scanner) | Forensik WordPress terinfeksi |
| [🌐 Website](https://github.com/ailinetech/ailinetech-website) | Source code website Ai Line Tech |

---

## 📄 Lisensi

MIT License — bebas digunakan dengan atribusi.

```
Copyright (c) 2025 Ai Line Tech
```

---

## 💬 Support

| Channel | Link |
|---------|------|
| 📧 Email | support@ailinetech.com |
| 🌐 Website | https://ailinetech.com |
| 🐛 Bug Report | [GitHub Issues](https://github.com/ailinetech/ubuntu-hardening/issues) |
| 💼 Premium Support | [Hubungi Kami](mailto:support@ailinetech.com) |

<div align="center">

---

**Dibuat dengan ❤️ oleh [Ai Line Tech](https://ailinetech.com)**

*Open Source · Premium Support Available*

</div>
