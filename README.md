# OpenClaw Configuration Backup

**Owner:** Handoyo Kristanto  
**Email:** handoyokristanto@gmail.com  


Repositori ini berisi cadangan konfigurasi, skrip, dan dokumentasi untuk proyek OpenClaw yang terintegrasi dengan LLM Gemini dan API Olsera.io.

## Struktur Direktori

*   `config/`: Berisi template file konfigurasi (misalnya `olsera.json.template`). **Jangan simpan token asli di sini secara publik.**
*   `skills/`: Berisi definisi skill OpenClaw dan skrip pendukung.
    *   `olsera/scripts/gemini_call.sh`: Skrip universal untuk memanggil API Gemini (Direct) atau OpenRouter.
*   `docs/`: Dokumentasi dan rangkuman sesi konfigurasi.

## Instruksi Pemulihan (Recovery)

1.  Clone repositori ini ke server target.
2.  Salin isi folder `skills/` ke direktori skill OpenClaw (biasanya `~/.openclaw/skills/`).
3.  Buat file kredensial di `~/.openclaw/credentials/olsera.json` berdasarkan `config/olsera.json.template`.
4.  Pastikan `OPENROUTER_API_KEY` (untuk OpenRouter) atau `GEMINI_ACCESS_TOKEN` (untuk Google Direct) diatur di lingkungan sistem atau container.
5.  Untuk OpenRouter, gunakan model ID `google/gemini-flash-1.5`.
6.  Restart layanan OpenClaw.

## Catatan Penting

Konfigurasi ini bersifat "fragile" (mudah error). Jika terjadi `Bad Gateway`, periksa status container Docker dan konfigurasi Traefik di Easypanel.
