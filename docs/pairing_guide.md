# Panduan Pairing Dashboard OpenClaw

Dokumen ini merangkum langkah-langkah strategis untuk melakukan pairing dashboard browser (node baru) ke Gateway OpenClaw.

## 1. Persiapan Data
Pastikan Anda memiliki informasi berikut dari file konfigurasi server (`openclaw.json`):
- **WebSocket URL**: `wss://openclaw.grandivo.cloud`
- **Gateway Token**: `bdab4d0351bee3b1fa715fd4dc58032f6f4caa8aa5daf247`

## 2. Inisiasi di Dashboard Browser
1. Buka browser dan akses dashboard OpenClaw (misalnya: `https://openclaw.grandivo.cloud/overview`).
2. Masukkan **WebSocket URL** dan **Gateway Token** yang benar.
   - *Penting*: Pastikan token disalin sepenuhnya tanpa ada bagian yang terpotong.
3. Klik tombol **Connect**.
4. Jika muncul pesan "Pairing Required", dashboard Anda telah mengirimkan permintaan ke server.

## 3. Persetujuan via VPS (SSH)
Karena alasan keamanan, setiap perangkat baru harus disetujui secara manual melalui baris perintah (CLI) di server:

1. Masuk ke VPS Anda melalui SSH.
2. Cek daftar perangkat yang sedang menunggu persetujuan (Pending):
   ```bash
   docker exec <container_name> node openclaw.mjs devices list
   ```
3. Temukan `Request ID` dari perangkat yang baru saja Anda coba hubungkan.
4. Setujui permintaan tersebut dengan perintah:
   ```bash
   docker exec <container_name> node openclaw.mjs devices approve <Request_ID>
   ```

## 4. Verifikasi
1. Kembali ke dashboard browser.
2. Klik tombol **Refresh** atau **Connect**.
3. Status seharusnya berubah menjadi **Connected** dengan Health **OK**.
4. Anda sekarang dapat menggunakan menu Chat atau fitur lainnya.

---
*Dokumen ini dibuat secara otomatis sebagai rangkuman proses pairing yang berhasil.*
