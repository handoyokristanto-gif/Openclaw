# Strategi Perbaikan Koneksi OpenRouter (Free Tier) - OpenClaw

**Tanggal:** 16 Juni 2026
**Status:** Terimplementasi

## 1. Masalah Utama
Penggunaan model `openrouter/auto` atau model tanpa suffix `:free` seringkali menyebabkan kegagalan koneksi (Error 403/401) pada akun dengan saldo nol, atau ketidakstabilan karena pemilihan model yang tidak optimal oleh router otomatis OpenRouter.

## 2. Solusi Strategis
Kami telah memperbarui skrip `skills/olsera/scripts/gemini_call.sh` dengan strategi berikut:

### A. Pemilihan Model Cerdas (Model Selection)
- **Default Reliable Model:** Menggunakan `google/gemini-2.0-flash-exp:free` sebagai default karena kecepatan, kapasitas konteks besar, dan ketersediaan gratis yang stabil.
- **Auto-Fallback:** Jika model yang dipilih (seperti `openrouter/auto`) gagal dengan error 400, 401, atau 403, skrip akan secara otomatis beralih ke model Gemini 2.0 Flash Free pada percobaan berikutnya.

### B. Efisiensi Token (Token Economy)
- **Max Tokens Limit:** Dibatasi ke `800` token (dari sebelumnya 1024) untuk menghemat kuota rate-limit OpenRouter free tier.
- **Optimized Payload:** Menambahkan parameter `temperature` dan `top_p` yang stabil untuk mengurangi variasi output yang tidak perlu.
- **Clean Input:** Menggunakan `jq` untuk sanitasi prompt guna menghindari error parsing JSON yang sering membuang token pada request yang gagal.

### C. Stabilitas Koneksi
- **Enhanced Headers:** Memperbarui `X-Title` dan `HTTP-Referer` untuk mematuhi kebijakan OpenRouter dan meningkatkan prioritas di beberapa provider.
- **Adaptive Retry:** Mekanisme retry yang lebih cerdas dengan jeda waktu yang ditingkatkan (`3 detik`) untuk menghindari `429 Too Many Requests`.

## 3. Cara Penggunaan
Pastikan variabel lingkungan `OPENROUTER_API_KEY` sudah diatur. Skrip akan secara otomatis menangani sisanya. Untuk memaksa model tertentu, ekspor variabel `MODEL`, misalnya:
```bash
export MODEL="deepseek/deepseek-chat:free"
```

## 4. Rekomendasi Model Free (Juni 2026)
1. `google/gemini-2.0-flash-exp:free` (Terbaik untuk general task)
2. `meta-llama/llama-3.3-70b-instruct:free` (Terbaik untuk penalaran kompleks)
3. `deepseek/deepseek-chat:free` (Sangat hemat dan cepat)
4. `mistralai/pixtral-12b:free` (Bagus untuk task multimodal/text)
