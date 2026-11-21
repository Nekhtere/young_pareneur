# Acara Puncak Approval Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ubah form forum 19 November menjadi Acara Puncak 27 November (satu sesi 14.00–17.00 WIB, kuota 80) dengan alur approval panitia, WA konfirmasi via deeplink, dan tiket email otomatis dari Gmail panitia lewat Apps Script.

**Architecture:** Static HTML tetap dipertahankan. Supabase menyimpan status dan menyediakan RPC untuk submit, kuota, approval, dan payload tiket. Dashboard panitia memanggil RPC approval, membuka `wa.me` dengan pesan terisi, dan memicu Apps Script lewat JSONP GET (Apps Script tidak mendukung CORS untuk POST lintas origin). Apps Script mengambil data tiket dari RPC Supabase, membuat PDF, dan mengirim dari Gmail panitia.

**Tech Stack:** HTML/CSS/JS vanilla, Supabase JS v2.45.4 (UMD), ExcelJS 4.4.0, jsPDF 2.5.1, Google Apps Script (GmailApp + HtmlService + ContentService), Python http.server untuk lokal.

**Spec:** Ringkasan disetujui dalam percakapan 2026-11-18 (lihat riwayat sesi). Tidak ada file spec terpisah.

## Global Constraints

- **Jangan commit dan jangan push.** Semua perubahan harus tetap di working tree untuk dicek lokal oleh user.
- Event: `Acara Puncak Business Growth & Digital Readiness Forum Batam 2026`.
- Tanggal/tempat/jam: `Jumat, 27 November 2026`, `Hotel Golden View Batam`, `14.00–17.00 WIB` (satu sesi saja).
- Kuota: `80` peserta total.
- Status default pendaftar: `menunggu`. Nilai status lain: `disetujui`, `ditolak`.
- Kanal WA: manual via deeplink `wa.me`, **tanpa** WhatsApp Business API / biaya.
- Kanal email: otomatis via Google Apps Script dari **Gmail panitia utama** yang dipakai login (`sb.auth`).
- Link grup WA yang dipakai: `https://chat.whatsapp.com/LczP3SJHP2aKeCa7XxJXr5?s=cl&p=a&iam=2` (asumsi disetujui; ganti jika ada link baru).
- Gaya kode: ES5-style `var`, fungsi named, tanpa framework — mengikuti ketiga file HTML yang ada.
- URL Supabase dan anon key diisi saat setup project baru (file ini sengaja tidak menyimpan kredensial).

## Review Focus

- Pendaftar mengirim form tanpa email → harus gagal validasi dengan pesan jelas, tidak bisa submit. Pin di Task 3 Step 2.
- Pendaftar submit saat kuota 80 terpenuhi → harus ditolak RPC dengan `KUOTA_PENUH` dan form menampilkan pesan penuh. Pin di Task 1 Step 4 dan Task 3 Step 5.
- Panitia klik Setujui dua kali → tidak boleh mengirim email dua kali. Pin di Task 4 Step 5 (`email_sent_at` guard).
- Apps Script gagal / URL belum diisi → dashboard harus tetap mencatat status `disetujui`, menampilkan error yang jelas, dan tetap membuka WA; tidak boleh menggugurkan approval. Pin di Task 4 Step 6.
- Pendaftar status `menunggu` atau `ditolak` tidak boleh melihat tiket aktif / tombol Download PDF / link grup. Pin di Task 3 Step 4.
- Kode registrasi dari pendaftar lama (19 November) tidak boleh ikut terubah atau terhapus. Pin di Task 1 Step 2 (migrasi additive + `if not exists`).

---

### Task 1: Migrasi Supabase (skema + RPC)

**Files:**
- Create: `supabase/2026-11-18-acara-puncak.sql`

**Interfaces:**
- Produces: kolom `email text`, `status text default 'menunggu'`, `wa_sent_at timestamptz`, `email_sent_at timestamptz` pada `public.registrations`.
- Produces: `public.submit_registration(p jsonb) returns text` — menerima `p->>'nama'|'jabatan'|'wa'|'email'|'usaha'|'bidang'|'skala'|'tk'|'sistem'|'minat'` serta `p->'butuh'`, `p->'pasar'` sebagai array teks; mengembalikan kode `BGAP-YYMMDD-NNN`; raise `KUOTA_PENUH` jika `count(*) >= 80`; set `sesi = 1`, `status = 'menunggu'`.
- Produces: `public.kuota_sesi() returns table(kuota int, terisi int, sisa int)` — satu baris, kuota 80.
- Produces: `public.set_status(p_id text, p_status text) returns boolean` — hanya menerima `disetujui`/`ditolak`, cocokkan `id::text = p_id`.
- Produces: `public.ticket_payload(p_kode text) returns jsonb` — security definer, hanya mengembalikan field tiket untuk baris ber-`status='disetujui'`, atau `null` jika tidak ada.
- Produces: `public.mark_sent(p_id text, p_kind text) returns boolean` — `p_kind` salah satu `wa`/`email`, mengisi `wa_sent_at`/`email_sent_at` jika belum terisi.

- [ ] **Step 1: Tulis file migrasi dengan kolom additive**

Buat `supabase/2026-11-18-acara-puncak.sql`. Bagian pertama: `alter table public.registrations add column if not exists` untuk keempat kolom di atas, lalu `add constraint ... check (status in (...))` secara kondisional (cek `pg_constraint` dulu agar aman dijalankan ulang). Jangan mengubah atau menghapus kolom lama.

- [ ] **Step 2: Verifikasi migrasi bersifat additive**

Run: `grep -E "drop column|truncate|delete from" supabase/2026-11-18-acara-puncak.sql`
Expected: tidak ada output.

- [ ] **Step 3: Tulis kelima RPC di file migrasi yang sama**

Gunakan `create or replace function`, `security definer`, `set search_path = public`. Untuk konversi array: `(select coalesce(array_agg(value), '{}'::text[]) from jsonb_array_elements_text(coalesce(p->'butuh', '[]'::jsonb)))`. Beri `grant execute` ke `anon` untuk `submit_registration`, `kuota_sesi`, `ticket_payload`; ke `authenticated` untuk `set_status` dan `mark_sent`.

- [ ] **Step 4: Verifikasi batas kuota dan status tertulis di SQL**

Run: `grep -nE "KUOTA_PENUH|80|menunggu|disetujui|ditolak" supabase/2026-11-18-acara-puncak.sql`
Expected: `KUOTA_PENUH` muncul, literal `80` muncul pada pengecekan kuota dan pada `kuota_sesi`, ketiga nilai status muncul.

- [ ] **Step 5: Serahkan instruksi eksekusi ke user (tidak dijalankan otomatis)**

Tulis di bagian paling atas file SQL sebagai komentar: paste seluruh isi file ke Supabase SQL Editor → Run. User yang menjalankan karena kredensial Supabase tidak boleh dipakai agen tanpa izin.

---

### Task 2: Endpoint Apps Script untuk email tiket

**Files:**
- Create: `apps-script/Code.gs`
- Create: `apps-script/README.md`

**Interfaces:**
- Consumes: `public.ticket_payload(p_kode text)` dari Task 1.
- Produces: web app `doGet(e)` dengan parameter `kode`, `secret`, `callback`; mengembalikan `ContentService.MimeType.JAVASCRIPT` berisi `callback({...})`.
- Produces: email dari akun Gmail yang men-deploy, subject `[Acara Puncak] Tiket Anda — <kode>`, HTML body + lampiran PDF `Tiket-<kode>.pdf`.
- Consumes: `SCRIPT_SECRET`, `SUPABASE_URL`, `SUPABASE_ANON_KEY` dari `PropertiesService.getScriptProperties()`.

- [ ] **Step 1: Tulis `doGet` dengan JSONP dan validasi secret**

`Code.gs`: sanitize `callback` dengan regex `^[A-Za-z_$][A-Za-z0-9_$]*$`, default `cb`. Jika `secret` tidak cocok dengan `SCRIPT_SECRET`, kembalikan `cb({"ok":false,"error":"UNAUTHORIZED"})`. Jika `kode` kosong, kembalikan `cb({"ok":false,"error":"NO_CODE"})`.

- [ ] **Step 2: Ambil data tiket dari Supabase lepas RPC**

Panggil `UrlFetchApp.fetch(SUPABASE_URL + '/rest/v1/rpc/ticket_payload', {method:'post', contentType:'application/json', headers:{apikey, Authorization:'Bearer ...'}, payload: JSON.stringify({p_kode: kode}), muteHttpExceptions:true})`. Parse `getContentText()`; jika null/error, kembalikan `cb({"ok":false,"error":"NOT_FOUND_OR_PENDING"})`.

- [ ] **Step 3: Buat PDF dan kirim email**

Fungsi `buildTicketHtml(d)` mengembalikan HTML dengan nama, jabatan, usaha, kode, `Jumat, 27 November 2026 · 14.00–17.00 WIB`, `Hotel Golden View Batam`. Fungsi `buildPdf(html)` memakai `HtmlService.createHtmlOutput(html).setTitle('Tiket').getAs('application/pdf')`. Kirim dengan `GmailApp.sendEmail(d.email, subject, 'Tiket terlampir.', {htmlBody: html, attachments: [pdf.setName('Tiket-'+kode+'.pdf')]})`. Bungkus `try/catch`, kembalikan `cb({"ok":true})` hanya jika berhasil.

- [ ] **Step 4: Tulis README setup sekali**

`apps-script/README.md` berisi urutan: buat project Apps Script baru → tempel `Code.gs` → Properties → Script properties isi 3 kunci → Deploy → New deployment → Web app, Execute as **Me**, Who has access **Anyone** → salin URL → tempel ke konstanta `MAIL_URL` di `dashboard.html`. Catat batas Gmail consumer ~500 email/hari dan bahwa secret harus diganti.

- [ ] **Step 5: Verifikasi statis**

Run: `grep -nE "doGet|MimeType.JAVASCRIPT|GmailApp.sendEmail|getAs\('application/pdf'\)|SCRIPT_SECRET" apps-script/Code.gs`
Expected: kelima pola muncul.

---

### Task 3: Form pendaftaran (`index.html`)

**Files:**
- Modify: `index.html` (hero dan intro copy, fieldset sesi, field email, state submit, PDF)

**Interfaces:**
- Consumes: `submit_registration(jsonb)`, `kuota_sesi()` dari Task 1.
- Produces: `last` object dengan field `{nama, jabatan, usaha, bidang, wa, email, kode}` untuk pembuat PDF.
- Produces: `body.sent` menandai tampilan "menunggu konfirmasi".

- [ ] **Step 1: Ubah seluruh copy event ke Acara Puncak**

Ganti baris 128 (`p.when`) menjadi `Jumat, 27 November 2026 · 14.00–17.00 WIB · Hotel Golden View Batam`. Ganti baris 129 `<h1>` menjadi `Acara Puncak Business Growth &amp; Digital Readiness Forum Batam 2026`. Ganti `<ul class="info">` (baris 150–154) menjadi tiga item: Tanggal `Jumat, 27 November 2026`, Waktu `14.00–17.00 WIB`, Tempat `Hotel Golden View Batam`. Ganti baris 155 menjadi `Tempat terbatas, hanya 80 peserta. Pendaftaran akan ditinjau panitia; Anda akan menerima konfirmasi via WhatsApp dan tiket via email.` Ganti teks di `makePdf` baris 417 menjadi `Jumat, 27 November 2026  |  14.00-17.00 WIB  |  Hotel Golden View Batam`, dan baris 419 judul PDF menjadi `Acara Puncak - Business Growth & Digital Readiness Forum Batam 2026`. Pada `makePdf`, hapus variabel `s1` dan `jam`, ganti `rows` menjadi `[["Peserta", ...],["Usaha", ...],["Waktu","14.00-17.00 WIB"]]` agar tidak lagi membaca `last.sesi`.

- [ ] **Step 2: Tambah field email wajib di langkah 1**

Di dalam `fieldset[data-step="0"]`, setelah field `f-wa`, tambahkan `.field` dengan `<label for="email">Alamat email</label>`, `<input id="email" type="text" inputmode="email" autocomplete="email" placeholder="Contoh: budi@perusahaan.co.id">`, dan `.msg` berisi `Tulis alamat email yang aktif untuk menerima tiket.`. Tambahkan aturan validasi di array `rules[0]`: `["email", function(){return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test($("email").value.trim())}, "email"]`.

- [ ] **Step 3: Hapus pilihan sesi, kunci ke satu sesi**

Hapus `.field#f-sesi` beserta aturan validasi `["sesi", ...]` dari `rules[0]`. Di `lanjut()`, hapus pembacaan `sesi` dari radio; set `var sesi=1;`. Di `data`, hapus properti `sesi` (RPC mengunci `sesi=1`) dan tambahkan `email: $("email").value.trim()`. Di blok `last`, sertakan `email: data.email`.

- [ ] **Step 4: Ubah layar setelah submit jadi status menunggu**

Ganti `<p class="sub">Profil usaha Anda sudah terkirim.</p>` menjadi `Profil usaha Anda sudah terkirim dan sedang ditinjau panitia.` Ubah `<dl>` menjadi tiga baris: Peserta, Usaha, dan `Status` dengan `<b id="dStatus">Menunggu konfirmasi panitia</b>`. Hapus baris `<div><dt>Sesi</dt>...`. Ganti teks `Kode registrasi` menjadi `Kode pendaftaran (aktif setelah disetujui)`. Pada `<p>` di `.tips` pertama, ganti menjadi `Anda akan menerima pesan WhatsApp berisi konfirmasi dan link grup, serta tiket PDF lewat email. Panitia akan memproses dalam waktu singkat.` Sembunyikan `<a class="join">` dan `<button id="dl">` dengan `hidden` pada kondisi awal.

- [ ] **Step 5: Ganti logika kuota**

Hapus fungsi `tutup()` dan pemanggilan `cekKuota()` lama. Fungsi `cekKuota()` baru: panggil `sb.rpc("kuota_sesi")`; jika `data[0].sisa <= 0`, nonaktifkan `#go`, ubah teksnya jadi `Pendaftaran ditutup, kuota penuh`. Panggil sekali saat init dan sekali lagi setelah klik `#go`.

- [ ] **Step 6: Sesuaikan pesan error submit**

Di `gagal()`, ganti deteksi `/SESI_PENUH/` menjadi `/KUOTA_PENUH/`, dengan pesan `Maaf, kuota 80 peserta sudah penuh.`

- [ ] **Step 7: Verifikasi statis form**

Run: `grep -nE "19 November|09.00–12.00|13.00–16.00|Sesi Pagi|Sesi Siang|33 peserta|SESI_PENUH" index.html`
Expected: hanya boleh muncul di dalam data base64/gambar atau tidak muncul sama sekali; pastikan tidak ada yang tersisa di teks Event dan script.

---

### Task 4: Dashboard approval (`dashboard.html`)

**Files:**
- Modify: `dashboard.html` (stats, filter, kartu pendaftar, aksi approval, export, wiring)

**Interfaces:**
- Consumes: `set_status(text,text)`, `mark_sent(text,text)`, `kuota_sesi()` dari Task 1; `MAIL_URL` dari Task 2 README.
- Produces: global `window.__mailCb` dipakai callback JSONP; tombol `setujui`, `tolak`, `wa`, `mail` pada tiap kartu.

- [ ] **Step 1: Ubah copy dan konstanta**

Baris 85 `p.when` → `Jumat, 27 November 2026 · 14.00–17.00 WIB · Hotel Golden View Batam`. `var CAP=33` → `var CAP=80`. Ganti `<small>kedua sesi</small>` menjadi `<small>kuota 80</small>`. Ganti dua kartu statistik sesi (baris 96–97) menjadi satu kartu `Terisi` dengan `<b id="s1">0<small> / 80</small></b>` dan bar `#b1`, plus satu kartu `Menunggu` (`#sW`) dan satu kartu `Disetujui` (`#sA`).

- [ ] **Step 2: Ganti filter sesi dengan filter status**

Baris 102: `<select id="fs">` dengan opsi `Semua status`, `Menunggu`, `Disetujui`, `Ditolak` (value `""`, `menunggu`, `disetujui`, `ditolak`). Di `draw()`, ganti `if(fs&&String(r.sesi)!==fs)return false;` menjadi `if(fs&&r.status!==fs)return false;`. Tambahkan `r.email` ke dalam string pencarian.

- [ ] **Step 3: Ubah kartu pendaftar**

Hapus `dl.appendChild(row("Sesi",sesiNama(r.sesi)))`. Tambahkan `row("Status", statusLabel(r.status))`, `row("Email", r.email || "-")`. Fungsi `statusLabel(s)` mengembalikan `Menunggu`/`Disetujui`/`Ditolak`. Hapus fungsi `sesiNama`.

- [ ] **Step 4: Tambah tombol aksi approval**

Pada kartu, sebelum tombol hapus, tambahkan:
- `setujui` — hanya tampil jika `r.status !== 'disetujui'`; warna `.next`.
- `tolak` — hanya tampil jika `r.status !== 'ditolak'`; warna `.back`.
- `wa` — hanya tampil jika `r.status === 'disetujui'`; teks `r.wa_sent_at ? 'Buka WA lagi' : 'Kirim WA'`.
- `mail` — hanya tampil jika `r.status === 'disetujui'`; teks `r.email_sent_at ? 'Kirim ulang email' : 'Kirim email tiket'`.

- [ ] **Step 5: Implementasi `setujui` dan `tolak`**

`var MAIL_URL=""` dan `var MAIL_SECRET=""` di bagian konstanta (diisi user dari README). Fungsi `ubahStatus(r, status)`: disable tombol, panggil `sb.rpc("set_status",{p_id:r.id,p_status:status})`; jika error, tampilkan `fail(...)` dan aktifkan kembali tombol. Jika sukses, perbarui objek `r` lokal, lalu:
- untuk `disetujui`: panggil `kirimEmail(r, false)` (Task 4 Step 6), lalu `kirimWa(r)` (Task 4 Step 7), lalu `stats();draw()`.
- untuk `ditolak`: hanya `stats();draw()`.

- [ ] **Step 6: Implementasi `kirimEmail(r, force)` dengan guard dan JSONP**

Jika `!MAIL_URL`, panggil `fail("URL Apps Script belum diisi. Baca apps-script/README.md.")` lalu return — status tetap `disetujui`. Jika `r.email_sent_at` dan user tidak menekan tombol kirim ulang, skip. Buat `window.__mailCb = function(res){ if(!res||!res.ok){fail("Email gagal: "+(res&&res.error||"tidak diketahui"))} else { sb.rpc("mark_sent",{p_id:r.id,p_kind:"email"}); } }`. Buat elemen `<script>` dengan `src = MAIL_URL + "?callback=__mailCb&kode=" + encodeURIComponent(r.kode) + "&secret=" + encodeURIComponent(MAIL_SECRET)`; `MAIL_SECRET` juga konstanta kosong yang diisi user. Pasang `onerror` untuk menampilkan pesan gagal. Hapus elemen script setelah 10 detik.

- [ ] **Step 7: Implementasi `kirimWa(r)`**

Bangun pesan: `Halo {nama}, pendaftaran Acara Puncak Business Growth & Digital Readiness Forum Batam 2026 Anda DISSETUJUI. Jumat, 27 November 2026, 14.00-17.00 WIB, Hotel Golden View Batam. Kode tiket: {kode}. Tiket PDF dikirim ke email Anda. Gabung grup: {LINK_GRUP}`. Buka `https://wa.me/<r.wa hanya angka, 08→62>?text=` + `encodeURIComponent(pesan)` dengan `window.open(..., "_blank", "noopener")`. Panggil `sb.rpc("mark_sent",{p_id:r.id,p_kind:"wa"})` lalu `draw()`. Di `draw()`, pasang handler: tombol `wa` → `kirimWa(r)`; tombol `mail` → `kirimEmail(r, true)` dengan argumen kedua menandakan kirim ulang eksplisit (melewati guard `email_sent_at`). Ubah tanda tangan `kirimEmail(r, force)` di Step 6.

- [ ] **Step 8: Perbarui `stats()`**

Hitung `c1 = rows.filter(r=>r.status==='disetujui').length`, `w = rows.filter(r=>r.status==='menunggu').length`. Isi `#sT`, `#sW`, `#sA`, `#s1` dengan `<small>/ 80</small>`. Bar `#b1` lebar `min(100, c1/80*100)%`. Hapus perhitungan `c2`.

- [ ] **Step 9: Perbarui export Excel**

Hapus kolom `Sesi` dari `cols` dan dari `ws.addRow` (baris 187 dan 215). Ubah `ws.addRow` menjadi menyertakan `r.status` dan `r.email` pada posisi yang sesuai. Banner baris 203–204 → `DATA PENDAFTAR ACARA PUNCAK FORUM BATAM 2026` dan `Jumat, 27 November 2026 · 14.00–17.00 WIB · Hotel Golden View Batam`. Baris 227–229: satu sheet `Semua Pendaftar` dengan info `Total N pendaftar | Disetujui: n | Menunggu: n | Ditolak: n`; hapus sheet `Sesi Pagi` dan `Sesi Siang`. Hapus variabel `c1`, `c2`.

- [ ] **Step 10: Verifikasi statis dashboard**

Run: `grep -nE "Sesi Pagi|Sesi Siang|sesiNama|33|19 November|fs.*sesi" dashboard.html`
Expected: tidak ada output.

---

### Task 5: Verifikasi lokal end-to-end

**Files:** tidak ada file baru.

**Interfaces:** memakai server Python yang sudah berjalan di `http://localhost:8000`.

- [ ] **Step 1: Cek server dan halaman**

Run: `curl -s http://localhost:8000/index.html | Select-String -Pattern "27 November|Acara Puncak|Alamat email"`
Expected: ketiga pola muncul.
Run: `curl -s http://localhost:8000/dashboard.html | Select-String -Pattern "Setujui|Menunggu|80"`
Expected: ketiga pola muncul.

- [ ] **Step 2: Cek form di browser**

Buka `http://localhost:8000/index.html`. Expected: hero menampilkan 27 November 2026, 14.00–17.00 WIB; tidak ada pilihan sesi; ada field email; klik "Isi formulir pendaftaran" tidak menampilkan radio sesi; mengirim tanpa email menampilkan pesan validasi email.

- [ ] **Step 3: Cek alur submit (butuh SQL migrasi terpasang)**

Isi form lengkap dengan email uji, submit. Expected: Supabase menerima baris dengan `status='menunggu'`, `email` terisi, layar menampilkan "Menunggu konfirmasi panitia", tombol Download PDF dan link grup tersembunyi.

- [ ] **Step 4: Cek dashboard approval**

Buka `http://localhost:8000/login.html`, login Google dengan akun panitia. Expected: statistik Menunggu/Disetujui/Terisi; filter status berfungsi; kartu menampilkan email dan status; tombol Setujui/Tolak tampil sesuai status.

- [ ] **Step 5: Cek efek approval**

Klik Setujui pada pendaftar uji. Expected: status berubah jadi Disetujui; tombol WA dan email muncul; tombol WA membuka tab `wa.me` dengan pesan terisi; jika `MAIL_URL` belum diisi, muncul pesan error jelas dan status tetap Disetujui; klik Setujui lagi tidak bisa (tombol hilang).

- [ ] **Step 6: Cek email (setelah user deploy Apps Script)**

Isi `MAIL_URL` dan `MAIL_SECRET`, ulangi approval pada pendaftar uji. Expected: email dengan lampiran PDF `Tiket-<kode>.pdf` masuk ke inbox email uji; dashboard menandai email terkirim.

- [ ] **Step 7: Laporan ke user**

Sampaikan: perubahan lokal selesai, belum di-commit/di-push; daftar file yang berubah; langkah yang masih perlu user lakukan (paste SQL ke Supabase, deploy Apps Script, isi `MAIL_URL`/`MAIL_SECRET`).
