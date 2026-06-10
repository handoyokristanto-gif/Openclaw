# Panduan Koneksi WhatsApp dengan OpenClaw

Dokumen ini menyediakan panduan komprehensif untuk menghubungkan WhatsApp dengan OpenClaw, termasuk pemecahan masalah umum terkait pemindaian barcode dan perbandingan antara penggunaan nomor khusus versus nomor pribadi.

## 1. Memahami Integrasi WhatsApp OpenClaw

OpenClaw mengintegrasikan WhatsApp melalui pustaka `whatsapp-web.js` (Baileys), yang mengotomatisasi antarmuka WhatsApp Web [1]. Ini berarti proses koneksi sangat bergantung pada fungsionalitas WhatsApp Web, yang memiliki karakteristik dan potensi masalah tertentu.

## 2. Penyebab Umum Error Pemindaian Barcode WhatsApp

Error saat memindai barcode WhatsApp adalah masalah yang sering ditemui. Berikut adalah beberapa penyebab utamanya:

*   **QR Code Kedaluwarsa atau Terdistorsi**: QR code yang dihasilkan oleh OpenClaw memiliki masa berlaku yang singkat. Jika tidak dipindai dengan cepat, atau jika tampilan QR code di terminal terdistorsi (terutama di lingkungan headless VPS), pemindaian bisa gagal [3].
*   **File Sesi Lama atau Rusak**: File sesi WhatsApp yang tersimpan di OpenClaw bisa menjadi usang atau rusak. Ini dapat menyebabkan konflik saat mencoba menghubungkan kembali, bahkan jika QR code berhasil dipindai [3].
*   **Batas Perangkat Tertaut WhatsApp**: WhatsApp membatasi jumlah perangkat yang dapat ditautkan ke satu akun (biasanya 4 perangkat). Jika batas ini tercapai, perangkat baru (termasuk OpenClaw) tidak dapat ditautkan [3].
*   **Kebutuhan Headless Chromium**: Karena OpenClaw mengotomatisasi WhatsApp Web, instalasi headless Chromium diperlukan di server Anda. Tanpa ini, `whatsapp-web.js` tidak dapat berfungsi dengan baik [3].

## 3. Solusi untuk Error Pemindaian Barcode

Jika Anda mengalami error saat memindai barcode, berikut adalah langkah-langkah pemecahan masalah yang dapat Anda coba:

1.  **Pastikan Gateway Berjalan dan Log Terlihat**: Pastikan layanan OpenClaw Gateway berjalan dan Anda dapat melihat log secara real-time. QR code akan muncul di log atau antarmuka web OpenClaw. Siapkan ponsel Anda sebelum memulai proses ini [3].
2.  **Mulai Ulang Gateway**: Jika QR code kedaluwarsa sebelum Anda sempat memindainya, mulai ulang gateway OpenClaw untuk menghasilkan QR code baru:
    ```bash
    openclaw gateway restart
    ```
3.  **Hapus Data Sesi Lama**: Jika QR code berhasil dipindai tetapi koneksi tetap gagal, kemungkinan ada file sesi lama yang rusak. Hentikan gateway, hapus direktori sesi WhatsApp, lalu mulai ulang gateway:
    ```bash
    openclaw gateway stop
    rm -rf ~/.openclaw/data/whatsapp/ # Sesuaikan path jika berbeda di konfigurasi Anda
    openclaw gateway start
    ```
    Anda dapat memeriksa `session_path` di `~/.openclaw/config/config.json` untuk memastikan Anda menghapus direktori yang benar [3].
4.  **Periksa Batas Perangkat Tertaut**: Pastikan Anda tidak mencapai batas 4 perangkat tertaut di WhatsApp. Buka WhatsApp di ponsel Anda, masuk ke Pengaturan > Perangkat Tertaut, dan hapus perangkat yang tidak digunakan untuk membebaskan slot [3].
5.  **Verifikasi Instalasi Chromium**: Pastikan headless Chromium terinstal di server Anda. Anda bisa memeriksanya dengan perintah `which chromium-browser` atau `which google-chrome` [3].
6.  **Gunakan Pairing Code (Alternatif QR)**: Beberapa versi OpenClaw atau konfigurasi tertentu mungkin mendukung metode *pairing code* sebagai alternatif QR code. Jika Anda menerima pesan dengan *pairing code* di WhatsApp, Anda perlu menyetujuinya di server:
    ```bash
    openclaw pairing approve whatsapp <code>
    ```
    Ganti `<code>` dengan kode yang Anda terima [4, 5].

## 4. Pilihan Nomor WhatsApp: Khusus vs. Pribadi

OpenClaw mendukung penggunaan nomor WhatsApp pribadi maupun nomor khusus. Namun, penggunaan nomor khusus sangat disarankan untuk stabilitas dan manajemen yang lebih baik.

| Fitur / Aspek        | Nomor Khusus (Sangat Disarankan)                                  | Nomor Pribadi (Self-Chat Mode)                                    |
| :------------------- | :---------------------------------------------------------------- | :---------------------------------------------------------------- |
| **Identitas**        | Memiliki profil/nama bot sendiri, terpisah dari akun pribadi.     | Menggunakan profil WhatsApp pribadi Anda.                         |
| **Interaksi**        | Berinteraksi dengan bot seperti chat dengan kontak lain.           | Berinteraksi dengan bot melalui fitur "Message Yourself" di WhatsApp. |
| **Pengaturan**       | `dmPolicy: "pairing"` atau `"allowlist"` untuk kontrol akses. | `selfChatMode: true` di konfigurasi [1].                          |
| **Kelebihan**        | Lebih rapi, kontrol akses jelas, mengurangi risiko banned akun pribadi. | Tidak perlu nomor atau perangkat tambahan.                        |
| **Kekurangan**       | Membutuhkan nomor telepon terpisah.                               | Chat bot bercampur dengan chat pribadi, potensi salah respons, risiko banned akun utama. |
| **Rekomendasi**      | Ideal untuk penggunaan serius, bisnis, atau integrasi kompleks.   | Cocok untuk pengujian cepat atau penggunaan sangat personal.      |

## 5. Konfigurasi `openclaw.json` untuk WhatsApp

Untuk mengaktifkan channel WhatsApp, pastikan konfigurasi Anda di `~/.openclaw/config/config.json` (atau lokasi serupa) sudah benar. Contoh konfigurasi dasar:

```json
{
  "channels": {
    "whatsapp": {
      "enabled": true,
      "accounts": {
        "default": {
          "phone_id": "my-whatsapp",
          "session_path": "/var/lib/openclaw/data/whatsapp",
          "auth_strategy": "LocalAuth",
          "dmPolicy": "pairing",
          "allowFrom": []
        }
      }
    }
  }
}
```

*   **`session_path`**: Pastikan direktori ini ada dan dapat ditulis oleh OpenClaw [3].
*   **`dmPolicy`**: Atur ke `"pairing"` (default, memerlukan persetujuan) atau `"allowlist"` jika Anda ingin mengontrol siapa saja yang dapat berinteraksi dengan bot [1].
*   **`allowFrom`**: Daftar nomor E.164 (tanpa `+`, dengan kode negara, diikuti `@c.us`) yang diizinkan berinteraksi dengan bot. Jika kosong, bot akan meminta persetujuan melalui *pairing* [1, 3].

## Referensi

1.  [WhatsApp - OpenClaw Docs](https://docs.openclaw.ai/channels/whatsapp)
2.  [OpenClaw — Personal AI Assistant](https://openclaw.ai/)
3.  [Fix OpenClaw WhatsApp Errors: 5 Proven Solutions - Stack Junkie](https://www.stack-junkie.com/blog/fix-openclaw-whatsapp-errors)
4.  [openclaw Add WhatsApp - GoPenAI](https://blog.gopenai.com/openclaw-add-whatsapp-27d9237d3872)
5.  [Simple Application Server:OpenClaw integration with WhatsApp - Alibaba Cloud](https://www.alibabacloud.com/help/en/simple-application-server/use-cases/openclaw-integrated-whatsapp)
