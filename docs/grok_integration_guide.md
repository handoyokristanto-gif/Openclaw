# Panduan Detail Integrasi xAI Grok di OpenClaw (Juni 2026)

Dokumen ini merinci hasil riset mendalam mengenai integrasi model Grok dari xAI ke dalam ekosistem OpenClaw, termasuk penanganan masalah yang sering terjadi.

## 1. Persyaratan Akun & Saldo
Berdasarkan kebijakan terbaru xAI per Juni 2026:
*   **Aktivasi API**: Akun baru memerlukan verifikasi kartu kredit/debit.
*   **Saldo Kredit**: Kredit gratis (seperti $25) seringkali baru aktif setelah melakukan **top-up minimal $5**. Tanpa saldo aktif (> $0), API akan memberikan respons kosong atau error "permission denied".
*   **Cek Saldo**: Pastikan saldo muncul di [console.x.ai](https://console.x.ai/billing).

## 2. Konfigurasi Provider xAI
OpenClaw memiliki plugin provider bawaan untuk `xai`.

### Metode Autentikasi:
1.  **API Key (Direkomendasikan untuk VPS)**:
    ```bash
    openclaw models auth login --provider xai --method api-key
    ```
    Atau atur variabel lingkungan: `export XAI_API_KEY=xai-...`
2.  **OAuth**: Cocok untuk pengguna X Premium/SuperGrok.

## 3. Daftar Model ID (Update Juni 2026)
Penggunaan ID model yang salah adalah penyebab utama error "Unknown model". Gunakan daftar berikut sesuai urutan prioritas:

| Model ID | Keterangan | Status |
| :--- | :--- | :--- |
| `xai/grok-4.3` | Model flagship terbaru. | Direkomendasikan |
| `xai/grok-2` | Model stabil versi sebelumnya. | Kompatibilitas Tinggi |
| `xai/grok-beta` | Jalur akses awal untuk API baru. | Alternatif |
| `xai/grok-4-vision` | Model dengan kemampuan analisis gambar. | Khusus Visi |

## 4. Troubleshooting Respons Kosong
Jika chat tidak memberikan jawaban meskipun koneksi terhubung:
1.  **Validasi Saldo**: Pastikan saldo di console.x.ai tidak $0.00.
2.  **Restart Gateway**: Setiap perubahan `openclaw.json` memerlukan restart container:
    ```bash
    docker restart <container_name>
    ```
3.  **Cek Log**: Gunakan perintah berikut untuk melihat error real-time:
    ```bash
    docker logs -f <container_name> | grep xai
    ```

## 5. Implementasi Khusus di Proyek Ini
Untuk memisahkan Grok dari OpenRouter, kami telah mengimplementasikan:
*   **File Config**: `config/grok.json.template`
*   **Skrip Pemanggil**: `skills/olsera/scripts/grok_call.sh` (Dilengkapi dengan penanganan error 429 dan pembersihan output JSON).

---
*Dokumen ini disusun untuk membantu sinkronisasi antara VPS dan Dashboard OpenClaw.*
