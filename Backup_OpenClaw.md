# Rangkuman Konfigurasi Backup OpenClaw

Dokumen ini menyajikan rangkuman detail mengenai konfigurasi backup recovery untuk OpenClaw, termasuk isi skrip backup, lokasi penyimpanan file backup, dan penjadwalan otomatisnya. Tujuan utama dari konfigurasi ini adalah untuk memastikan ketersediaan data dan konfigurasi OpenClaw dengan menerapkan kebijakan rotasi backup selama 7 hari.

## 1. Skrip Backup OpenClaw

Skrip backup yang digunakan adalah `openclaw-backup-updated.sh`, yang terletak di dalam direktori workspace OpenClaw. Skrip ini dirancang untuk melakukan backup harian dan mengelola retensi file backup.

**Lokasi Skrip:** `/home/ubuntu/.openclaw/workspace/openclaw-backup-updated.sh`

**Isi Skrip:**
```bash
#!/usr/bin/env bash
# OpenClaw Updated Backup & Recovery Script
# Rotation: 7 Days (7 Files)

set -euo pipefail

# --- Configuration ---
BACKUP_DIR="$HOME/backups/openclaw"
STATE_DIR="$HOME/.openclaw"
RETENTION_DAYS=7
DATE=$(date +%Y-%m-%d)
ARCHIVE_NAME="openclaw-backup-$DATE.tar.gz"
ARCHIVE_PATH="$BACKUP_DIR/$ARCHIVE_NAME"
LOG_FILE="$BACKUP_DIR/backup.log"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

echo "[$(date)] Starting OpenClaw backup..." | tee -a "$LOG_FILE"

# --- Step 1: Create Backup ---
# Using the built-in openclaw CLI if available, otherwise fallback to tar
if command -v openclaw &> /dev/null; then
    echo "[$(date)] Using OpenClaw CLI for backup..." | tee -a "$LOG_FILE"
    openclaw backup create --output "$BACKUP_DIR" --verify >> "$LOG_FILE" 2>&1
    # Note: openclaw CLI usually generates its own timestamped filename
else
    echo "[$(date)] OpenClaw CLI not found, using manual tar backup..." | tee -a "$LOG_FILE"
    tar -czf "$ARCHIVE_PATH" -C "$HOME" .openclaw .env 2>> "$LOG_FILE"
fi

# --- Step 2: Verification ---
if [ -f "$ARCHIVE_PATH" ] || ls "$BACKUP_DIR"/*"$DATE"*.tar.gz &> /dev/null; then
    echo "[$(date)] Backup created successfully." | tee -a "$LOG_FILE"
else
    echo "[$(date)] ERROR: Backup failed!" | tee -a "$LOG_FILE"
    exit 1
fi

# --- Step 3: Rotation (Keep last 7 days) ---
echo "[$(date)] Cleaning up backups older than $RETENTION_DAYS days..." | tee -a "$LOG_FILE"
# This find command identifies and deletes files older than 7 days
find "$BACKUP_DIR" -name "openclaw-backup-*.tar.gz" -mtime +$RETENTION_DAYS -delete
# Also cleanup CLI generated backups if they follow a different pattern
find "$BACKUP_DIR" -name "*-openclaw-backup.tar.gz" -mtime +$RETENTION_DAYS -delete

echo "[$(date)] Backup process completed." | tee -a "$LOG_FILE"
echo "------------------------------------------------" >> "$LOG_FILE"
```

**Penjelasan Skrip:**
*   **Konfigurasi**: Mendefinisikan direktori backup (`BACKUP_DIR`), direktori state OpenClaw (`STATE_DIR`), jumlah hari retensi (`RETENTION_DAYS`), dan format nama file backup.
*   **Pembuatan Backup**: Skrip akan mencoba menggunakan perintah `openclaw backup create` bawaan jika tersedia. Jika tidak, ia akan fallback ke perintah `tar` standar untuk mengarsipkan direktori `.openclaw` dan file `.env`.
*   **Verifikasi**: Setelah backup dibuat, skrip melakukan verifikasi dasar untuk memastikan file backup berhasil dibuat.
*   **Rotasi**: Menggunakan perintah `find` untuk menghapus file backup yang lebih tua dari `RETENTION_DAYS` (7 hari), sehingga hanya 7 file backup terbaru yang dipertahankan.

## 2. Lokasi Penyimpanan Backup

Semua file backup dan log aktivitas disimpan dalam satu direktori khusus:

*   **Direktori Utama Backup**: `/home/ubuntu/backups/openclaw/`
*   **Contoh File Backup**: `openclaw-backup-YYYY-MM-DD.tar.gz` (nama file akan disesuaikan dengan tanggal saat backup dibuat).
*   **File Log Aktivitas**: `/home/ubuntu/backups/openclaw/backup.log` (berisi catatan setiap kali skrip backup dijalankan, termasuk status keberhasilan atau kegagalan).

## 3. Penjadwalan Cron

Skrip backup dijadwalkan untuk berjalan secara otomatis setiap hari menggunakan system crontab. Ini memastikan bahwa proses backup berjalan secara teratur tanpa intervensi manual.

**Entri Cron:**
```
0 3 * * * /home/ubuntu/.openclaw/workspace/openclaw-backup-updated.sh >> /home/ubuntu/backups/openclaw/backup.log 2>&1
```

**Penjelasan Penjadwalan:**
*   Skrip akan dieksekusi setiap hari pada pukul **03:00 pagi**.
*   Output standar dan error dari eksekusi skrip akan diarahkan ke file log `/home/ubuntu/backups/openclaw/backup.log`.
*   Penggunaan **system crontab** direkomendasikan karena lebih andal untuk tugas administratif dan akan tetap berjalan meskipun aplikasi OpenClaw mungkin tidak aktif atau mengalami masalah.

## 4. Rotasi Backup (7 Hari)

Kebijakan rotasi 7 hari diimplementasikan dengan menghapus file backup yang telah berusia lebih dari 7 hari. Ini memastikan bahwa hanya ada 7 file backup, masing-masing mewakili backup dari hari yang berbeda, yang tersimpan di direktori backup. Hal ini membantu mengelola penggunaan ruang disk sambil tetap menyediakan riwayat backup yang cukup untuk pemulihan.

## Kesimpulan

Konfigurasi backup ini menyediakan solusi yang kuat untuk melindungi data dan konfigurasi OpenClaw Anda. Dengan skrip otomatis dan penjadwalan harian, Anda dapat yakin bahwa salinan backup terbaru selalu tersedia, dengan kebijakan retensi yang efisien. Untuk prosedur pemulihan yang lebih rinci, silakan merujuk pada dokumentasi OpenClaw atau rangkuman sebelumnya yang telah saya berikan.
