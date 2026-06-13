# Integrasi OpenClaw dengan LLM Grok

Dokumen ini merangkum bagaimana OpenClaw terhubung dan berinteraksi dengan model bahasa besar (LLM) Grok dari xAI, berdasarkan analisis repositori OpenClaw dan dokumentasi terkait.

## Gambaran Umum Koneksi

OpenClaw menyediakan plugin penyedia `xai` bawaan untuk model Grok. Untuk sebagian besar pengguna, jalur yang direkomendasikan adalah Grok OAuth dengan langganan SuperGrok atau X Premium yang memenuhi syarat. OpenClaw beroperasi secara lokal: Gateway, konfigurasi, perutean, dan alat berjalan di mesin pengguna, sementara permintaan model Grok diautentikasi melalui xAI dan dikirim ke API xAI. [1]

OAuth tidak memerlukan kunci API xAI dan tidak memerlukan aplikasi Grok Build. xAI mungkin masih menampilkan Grok Build di layar persetujuan karena OpenClaw menggunakan klien OAuth bersama xAI. [1]

## Metode Penyiapan

Ada beberapa jalur penyiapan tergantung pada status instalasi OpenClaw Anda:

### Instalasi OpenClaw Baru

Saat menyiapkan Gateway lokal baru, jalankan `openclaw onboard --install-daemon`, lalu pilih opsi xAI/Grok OAuth pada langkah model/autentikasi. Untuk VPS atau melalui SSH, gunakan `openclaw onboard --install-daemon --auth-choice xai-device-code`. [1]

### Instalasi OpenClaw yang Ada

Jika OpenClaw sudah dikonfigurasi, cukup masuk ke xAI. Gunakan `openclaw models auth login --provider xai --method oauth`. Untuk Gateway yang berjalan melalui SSH, Docker, atau VPS, gunakan `openclaw models auth login --provider xai --device-code`. Untuk menjadikan Grok model default setelah masuk, terapkan secara terpisah dengan `openclaw models set xai/grok-4.3`. [1]

### Jalur Kunci API

Penyiapan kunci API masih berfungsi untuk kunci Konsol xAI dan untuk permukaan media yang memerlukan konfigurasi penyedia yang didukung kunci. Contoh: `openclaw models auth login --provider xai --method api-key` dan `export XAI_API_KEY=xai-...`. [1]

## Model Grok yang Didukung

OpenClaw menyertakan model obrolan xAI saat ini secara langsung, diurutkan terbaru terlebih dahulu dalam pemilih model:

| Keluarga Model | ID Model                               |
| :------------- | :------------------------------------- |
| Grok Build 0.1 | `grok-build-0.1`                       |
| Grok 4.3       | `grok-4.3`                             |
| Grok 4.20 Beta | `grok-4.20-beta-latest-reasoning`      |
|                | `grok-4.20-beta-latest-non-reasoning`  |

Plugin ini masih meneruskan resolusi slug Grok 3, Grok 4, Grok 4 Fast, Grok 4.1 Fast, dan Grok Code yang lebih lama untuk konfigurasi yang ada. [1]

## Fitur OpenClaw dengan Integrasi xAI

Plugin xAI yang dibundel memetakan permukaan API publik xAI saat ini ke kontrak penyedia dan alat bersama OpenClaw. Berikut adalah beberapa kemampuan yang didukung:

| Kemampuan xAI            | Permukaan OpenClaw       | Status |
| :----------------------- | :----------------------- | :----- |
| Obrolan / Respons        | `xai/<model>` model provider | Ya     |
| Pencarian web sisi server | `web_search` provider `grok` | Ya     |
| Pencarian X sisi server   | `x_search` alat          | Ya     |
| Eksekusi kode sisi server | `code_execution` alat    | Ya     |
| Gambar                   | `image_generate`         | Ya     |
| Video                    | `video_generate`         | Ya     |
| Batch text-to-speech     | `messages.tts.provider: "xai"` / `tts` | Ya     |
| Batch speech-to-text     | `tools.media.audio` / pemahaman media | Ya     |

### Pembuatan Video

Plugin xAI mendaftarkan pembuatan video melalui alat `video_generate` bersama. Model video default adalah `xai/grok-imagine-video`. Ini mendukung mode text-to-video, image-to-video, pembuatan gambar referensi, pengeditan video jarak jauh, dan ekstensi video. [1]

### Pembuatan Gambar

Plugin xAI mendaftarkan pembuatan gambar melalui alat `image_generate` bersama. Model gambar default adalah `xai/grok-imagine-image`. Ini mendukung mode text-to-image dan pengeditan gambar referensi. [1]

### Text-to-Speech (TTS)

Plugin xAI mendaftarkan text-to-speech melalui antarmuka penyedia `tts`. Ini mendukung berbagai suara (misalnya, `eve`, `ara`, `rex`) dan format (misalnya, `mp3`, `wav`). [1]

### Speech-to-Text (STT)

Plugin xAI mendaftarkan batch speech-to-text melalui antarmuka transkripsi pemahaman media OpenClaw. Model default adalah `grok-stt`. Ini juga mendukung streaming speech-to-text untuk audio panggilan suara real-time. [1]

### Pencarian X

Plugin xAI yang dibundel mengekspos `x_search` sebagai alat OpenClaw untuk mencari konten X (sebelumnya Twitter) melalui Grok. Ini mendukung kueri semantik, pemfilteran kata kunci, pencarian postingan spesifik pengguna, dan pengambilan utas, memberikan agen Grok umpan langsung ke data X. [1] [2]

## Pertimbangan Biaya

OpenClaw sendiri adalah sumber terbuka dan gratis. Namun, penggunaan alat berbasis API (seperti pencarian web dan eksekusi kode) dikenakan biaya per panggilan oleh xAI. Langganan SuperGrok atau X Premium (melalui jalur login OAuth) melewati penagihan API langsung untuk obrolan standar, tetapi penggunaan alat yang berat masih akan menimbulkan biaya terpisah. [2]

## Pemecahan Masalah OAuth

*   Jika OAuth browser tidak dapat mencapai `127.0.0.1:56121`, gunakan `openclaw models auth login --provider xai --device-code`.
*   Jika masuk berhasil tetapi Grok bukan model default, jalankan `openclaw models set xai/grok-4.3`.
*   Untuk memeriksa profil otentikasi xAI yang disimpan, jalankan `openclaw models auth list --provider xai` atau `openclaw models status`.
*   xAI memutuskan akun mana yang dapat menerima token API OAuth. Jika akun tidak memenuhi syarat, coba jalur kunci API atau periksa langganan di sisi xAI. [1]

## Kesimpulan

Integrasi OpenClaw dengan Grok LLM menyediakan cara yang kuat dan fleksibel bagi pengguna untuk memanfaatkan kemampuan AI canggih Grok dalam lingkungan agen AI lokal. Dengan dukungan untuk berbagai metode koneksi, model, dan fitur, OpenClaw memungkinkan pengguna untuk menyesuaikan pengalaman AI mereka dan memanfaatkan kekuatan Grok untuk berbagai aplikasi.

## Referensi

[1] OpenClaw Docs. (n.d.). *xAI*. Retrieved from [https://docs.openclaw.ai/providers/xai](https://docs.openclaw.ai/providers/xai)
[2] basenor. (2026, May 19). *Grok Subscribers Can Now Use xAI in OpenClaw Platform*. Retrieved from [https://www.basenor.com/blogs/news/grok-subscribers-can-now-use-xai-in-openclaw-platform](https://www.basenor.com/blogs/news/grok-subscribers-can-now-use-xai-in-openclaw-platform)
