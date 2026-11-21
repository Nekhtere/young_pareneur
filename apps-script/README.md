# Email tiket Acara Puncak — Google Apps Script

Gratis, dikirim dari **Gmail panitia utama** (akun yang men-deploy script). Tidak perlu API berbayar.

## Setup sekali

1. Buka https://script.google.com → **New project**.
2. Hapus isi default, tempel seluruh isi `Code.gs`, simpan.
3. **Project Settings** → **Script properties** → tambahkan 3 kunci:

   | Property | Nilai |
   |---|---|
   | `SCRIPT_SECRET` | string acak rahasia, mis. `puncak2026-<acak>` |
   | `SUPABASE_URL` | `https://civmaituvwjywwpceqai.supabase.co` |
   | `SUPABASE_SERVICE_KEY` | service_role key dari Supabase → Project Settings → API (rahasia, jangan dipakai di browser) |

4. **Deploy** → **New deployment** → pilih **Web app**:
   - Description: `Tiket Acara Puncak 2026`
   - Execute as: **Me**
   - Who has access: **Anyone**
5. Klik **Deploy**, izinkan akses akun Google, lalu salin **Web app URL**.
6. Tempel URL itu ke konstanta `MAIL_URL` di bagian atas script `dashboard.html`.
7. Tempel nilai `SCRIPT_SECRET` yang sama ke konstanta `MAIL_SECRET` di `dashboard.html`.

## Cara kerja

- Dashboard memanggil URL lewat JSONP (`?callback=...&kode=...&secret=...`) karena Apps Script tidak mendukung CORS untuk POST lintas origin.
- Script mengambil data tiket dari RPC Supabase `ticket_payload`, lalu mengirim email berisi HTML + lampiran PDF `Tiket-<kode>.pdf`.
- Email hanya terkirim untuk pendaftar berstatus `disetujui`.

## Catatan

- Batas pengiriman Gmail consumer sekitar 500 email/hari — kuota 80 peserta aman.
- Rahasiakan `SCRIPT_SECRET`; siapa pun yang memilikinya bisa memicu pengiriman email.
- Perubahan kode Apps Script harus di-deploy ulang (**Manage deployments** → versi baru) agar URL memperbarui.
