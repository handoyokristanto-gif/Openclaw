# Panduan Koneksi OpenClaw dengan OpenRouter

Dokumen ini menyediakan panduan lengkap untuk mengkoneksikan OpenClaw Anda dengan OpenRouter, termasuk langkah-langkah konfigurasi, pemilihan model, dan tips pemecahan masalah. OpenRouter memungkinkan OpenClaw untuk mengakses ratusan model LLM dari berbagai penyedia melalui satu API Key dan *endpoint* yang terpadu.

## 1. Mengapa Menggunakan OpenRouter?

OpenRouter bertindak sebagai *gateway* API terpadu yang merutekan permintaan LLM ke banyak model dari penyedia seperti Anthropic, OpenAI, Google, Meta, dan Mistral. Keuntungannya meliputi: [3]

*   **Satu API Key:** Anda hanya perlu satu API Key untuk mengakses berbagai model.
*   **Penagihan Terkonsolidasi:** Semua penggunaan model ditagih di satu tempat.
*   **Kompatibilitas OpenAI:** OpenRouter kompatibel dengan API OpenAI, sehingga mudah diintegrasikan dengan alat yang sudah mendukung OpenAI.
*   **Model Fallback Otomatis:** OpenRouter dapat secara otomatis mencoba model lain jika model utama gagal atau mencapai batas *rate limit*.

## 2. Prasyarat

Sebelum memulai, pastikan Anda memiliki hal-hal berikut:

*   **Akun OpenRouter:** Buat akun di [openrouter.ai](https://openrouter.ai).
*   **API Key OpenRouter:** Buat API Key baru di halaman [openrouter.ai/keys](https://openrouter.ai/keys). Salin kunci ini (biasanya dimulai dengan `sk-or-`).
*   **Kredit OpenRouter:** Tambahkan kredit ke akun OpenRouter Anda. OpenRouter mengenakan biaya kecil saat pembelian kredit, tetapi biaya inferensi model sama dengan biaya langsung dari penyedia model. [3]

## 3. Langkah-langkah Konfigurasi OpenClaw dengan OpenRouter

Ada dua metode utama untuk mengkonfigurasi OpenRouter di OpenClaw:

### Metode A: Menggunakan Perintah `openclaw onboard` (Disarankan)

Ini adalah cara termudah dan paling direkomendasikan untuk mengkonfigurasi OpenRouter:

1.  **Jalankan Perintah Onboarding:** Buka terminal Anda dan jalankan perintah berikut, ganti `YOUR_OPENROUTER_API_KEY` dengan API Key Anda yang sebenarnya:

    ```bash
    openclaw onboard --auth-choice apiKey --token-provider openrouter --token "YOUR_OPENROUTER_API_KEY"
    ```

    Atau, Anda bisa mengekspor API Key sebagai variabel lingkungan terlebih dahulu:

    ```bash
    export OPENROUTER_API_KEY="sk-or-v1-YOUR_OPENROUTER_API_KEY"
    openclaw onboard --auth-choice apiKey --token-provider openrouter --token "$OPENROUTER_API_KEY"
    ```

    Perintah ini akan menulis kredensial ke konfigurasi OpenClaw Anda dan mengatur OpenRouter sebagai penyedia aktif. [3]

2.  **Atur Model Default (Opsional):** Secara default, onboarding akan mengatur `openrouter/auto`. Jika Anda ingin menggunakan model spesifik, Anda bisa mengaturnya nanti:

    ```bash
    openclaw models set openrouter/<provider>/<model>
    # Contoh: openclaw models set openrouter/google/gemini-flash-1.5
    # Contoh: openclaw models set openrouter/x-ai/grok-4.1-fast
    ```

### Metode B: Konfigurasi Manual di `openclaw.json`

Jika Anda lebih suka mengedit file konfigurasi secara langsung, Anda dapat menambahkan atau memodifikasi `openclaw.json` Anda. Lokasi file ini biasanya di direktori instalasi OpenClaw Anda.

Contoh konfigurasi minimal:

```json
{
  "env": { "OPENROUTER_API_KEY": "sk-or-v1-YOUR_OPENROUTER_API_KEY" },
  "agents": {
    "defaults": {
      "model": { "primary": "openrouter/auto" }
    }
  }
}
```

**Penting:** Pastikan `OPENROUTER_API_KEY` diisi dengan API Key Anda. `agents.defaults.model.primary` menentukan model yang akan digunakan oleh semua agen secara default. [3]

### Pemilihan Model

Setiap model OpenRouter mengikuti format `openrouter/<provider>/<model>`. Beberapa contoh:

*   `openrouter/anthropic/claude-sonnet-4-6`
*   `openrouter/openai/gpt-4o`
*   `openrouter/google/gemini-2.0-flash-001`
*   `openrouter/meta-llama/llama-3.3-70b-instruct`
*   `openrouter/x-ai/grok-4.1-fast`

Anda juga bisa menambahkan sufiks varian seperti `:free` untuk model *free tier*, `:nitro` untuk inferensi kecepatan tinggi, atau `:thinking` untuk mode penalaran yang diperpanjang. Contoh: `openrouter/anthropic/claude-sonnet-4-6:thinking`. [3]

## 4. Pembaruan Skrip `gemini_call.sh`

Skrip `gemini_call.sh` di repositori Anda telah diperbarui untuk lebih baik dalam menangani penamaan model OpenRouter dan menyertakan *header* atribusi yang direkomendasikan oleh OpenRouter. Perubahan utama meliputi:

*   **Model Default:** Mengubah model default menjadi `openrouter/auto` untuk fleksibilitas yang lebih baik.
*   **Header `X-OpenRouter-Title`:** Menambahkan *header* ini untuk atribusi yang tepat ke OpenClaw saat melakukan panggilan API ke OpenRouter. [1]

Pastikan Anda memiliki versi terbaru dari skrip ini di `skills/olsera/scripts/gemini_call.sh`.

## 5. Pemecahan Masalah Umum

Jika Anda mengalami kegagalan koneksi atau masalah lain, pertimbangkan hal-hal berikut:

*   **API Key Tidak Valid/Kadaluarsa:** Pastikan API Key OpenRouter Anda benar dan masih aktif. Buat yang baru jika ragu.
*   **Kredit Habis:** Periksa saldo kredit Anda di OpenRouter. Jika habis, model tidak akan merespons.
*   **Variabel Lingkungan:** Pastikan `OPENROUTER_API_KEY` telah diekspor dengan benar di lingkungan shell tempat Anda menjalankan OpenClaw.
*   **Format Model:** Pastikan Anda menggunakan format model yang benar (`openrouter/<provider>/<model>`). Kesalahan penulisan dapat menyebabkan kegagalan routing. [3]
*   **Model Tidak Tersedia:** Beberapa model mungkin tidak tersedia di OpenRouter atau memiliki batasan geografis. Coba model lain jika Anda terus mengalami masalah.
*   **OpenClaw Gateway:** Pastikan OpenClaw Gateway Anda berjalan dengan benar. Anda bisa memeriksa log atau statusnya.
*   **Header HTTP:** Skrip `gemini_call.sh` yang diperbarui sudah menyertakan *header* yang diperlukan (`HTTP-Referer` dan `X-Title`), pastikan tidak ada konflik atau penghapusan *header* ini jika Anda memodifikasi skrip lebih lanjut.
*   **Perbarui OpenClaw:** Pastikan instalasi OpenClaw Anda adalah versi terbaru, karena pembaruan seringkali menyertakan perbaikan bug dan peningkatan kompatibilitas. [2]

## Referensi

[1] OpenClaw. (n.d.). *gemini_call.sh*. Retrieved from `/home/ubuntu/Openclaw/skills/olsera/scripts/gemini_call.sh`
[2] OpenClaw Docs. (n.d.). *Troubleshooting*. Retrieved from [https://docs.openclaw.ai/gateway/troubleshooting](https://docs.openclaw.ai/gateway/troubleshooting)
[3] Stack Junkie. (2026, March 26). *OpenClaw OpenRouter Setup: One API Key for Hundreds of Models*. Retrieved from [https://www.stack-junkie.com/blog/openclaw-openrouter-setup-guide](https://www.stack-junkie.com/blog/openclaw-openrouter-setup-guide)
[4] OpenClaw Docs. (n.d.). *OpenRouter*. Retrieved from [https://docs.openclaw.ai/providers/openrouter](https://docs.openclaw.ai/providers/openrouter)
