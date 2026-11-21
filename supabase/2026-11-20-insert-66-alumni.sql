-- =====================================================================
-- Acara Puncak Business Growth & Digital Readiness Forum Batam 2026
-- Impor 66 Data Peserta Forum Sebelumnya (Kamis, 19 Nov 2026)
-- Status: Disetujui
-- Tanggal Eksekusi: 20 November 2026
--
-- CARA PAKAI:
-- Salin dan jalankan seluruh isi file ini di Supabase SQL Editor.
-- =====================================================================

with v_base as (
  select coalesce(max(nomor), 0) as max_no from public.registrations where sesi = 1
),
raw_data(kode, nama, jabatan, wa, usaha, bidang, skala, tk, sistem, butuh, pasar, minat, created_at) as (
  values
    ('BGAP-261119-S1-001', 'Anis Rohmawati', 'Pemilik usaha', '6281326464434', 'Bandasea', 'Makanan dan minuman', 'Menengah', '11–50 orang', 'Aplikasi kasir atau POS', ARRAY['Ekspansi']::text[], ARRAY['Batam dan Kepri', 'Singapura']::text[], 'Ya, hubungi saya', '2026-11-16 17:17:00+07'::timestamptz),
    ('BGAP-261119-S1-002', 'Heryatul Azizah Zein', 'Manajer pemasaran dan penjualan', '6285268938161', 'Bina Cakra', 'Makanan dan minuman', 'Menengah', '51–100 orang', 'Excel atau spreadsheet', ARRAY['Stok dan gudang']::text[], ARRAY['Batam dan Kepri']::text[], 'Ya, hubungi saya', '2026-11-16 17:32:00+07'::timestamptz),
    ('BGAP-261119-S1-003', 'Shovia Sulistiana Putri', 'Manajer pemasaran dan penjualan', '6283111646423', 'Mukafa', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Excel atau spreadsheet', ARRAY['Keuangan', 'Pembelian', 'Distribusi']::text[], ARRAY['Batam dan Kepri', 'Nasional', 'Singapura', 'Jepang']::text[], 'Ya, hubungi saya', '2026-11-16 17:50:00+07'::timestamptz),
    ('BGAP-261119-S1-004', 'Nirwana sitorus', 'Pemilik usaha', '6281372524748', 'Intan parfum', 'Fashion', 'Menengah', '1–10 orang', 'Manual atau buku catatan', ARRAY['Penjualan']::text[], ARRAY['Batam dan Kepri']::text[], 'Ya, hubungi saya', '2026-11-16 17:59:00+07'::timestamptz),
    ('BGAP-261119-S1-006', 'Hartini', 'Pemilik usaha', '6281270007193', 'Galeri nusantara', 'Kerajinan tangan', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Keuangan', 'Penjualan', 'Distribusi']::text[], ARRAY['Batam dan Kepri', 'Nasional']::text[], 'Belum, saya lihat dulu', '2026-11-16 18:18:00+07'::timestamptz),
    ('BGAP-261119-S1-007', 'Indrawati', 'Pemilik usaha', '6282170584176', 'Rang Caniago', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Keuangan']::text[], ARRAY['Batam dan Kepri', 'Singapura']::text[], 'Ya, hubungi saya', '2026-11-16 18:19:00+07'::timestamptz),
    ('BGAP-261119-S1-008', 'Umi Mahfuroh', 'Pemilik usaha', '6281233577136', 'Dapur Bu Umi', 'Baking (kue panggang)', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Penjualan']::text[], ARRAY['Batam dan Kepri']::text[], 'Ya, hubungi saya', '2026-11-16 18:23:00+07'::timestamptz),
    ('BGAP-261119-S1-009', 'Rini Asih', 'Pemilik usaha', '6281365960334', 'Tarika', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Keuangan', 'Penjualan']::text[], ARRAY['Batam dan Kepri', 'Singapura']::text[], 'Ya, hubungi saya', '2026-11-16 18:26:00+07'::timestamptz),
    ('BGAP-261119-S1-010', 'Zuharni', 'Pemilik usaha', '6281213776281', 'Unizu', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Penjualan', 'Produksi']::text[], ARRAY['Batam dan Kepri']::text[], 'Ya, hubungi saya', '2026-11-16 18:29:00+07'::timestamptz),
    ('BGAP-261119-S1-011', 'melda', 'Pemilik usaha', '628139700523', 'melda snack', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Keuangan']::text[], ARRAY['Batam dan Kepri', 'Singapura']::text[], 'Ya, hubungi saya', '2026-11-16 18:30:00+07'::timestamptz),
    ('BGAP-261119-S1-012', 'Raja Novika Anraini', 'Pemilik usaha', '6285272251805', 'Nadia Ducok', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Aplikasi kasir atau POS', ARRAY['Penjualan']::text[], ARRAY['Batam dan Kepri']::text[], 'Ya, hubungi saya', '2026-11-16 18:31:00+07'::timestamptz),
    ('BGAP-261119-S1-013', 'Maya Ridha', 'Pemilik usaha', '62895393078521', 'Bunanos cake', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Keuangan', 'Penjualan']::text[], ARRAY['Batam dan Kepri']::text[], 'Ya, hubungi saya', '2026-11-16 18:34:00+07'::timestamptz),
    ('BGAP-261119-S1-014', 'Henny', 'Pemilik usaha', '6285365141818', 'Henny Cooks', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Keuangan', 'Penjualan', 'Produksi']::text[], ARRAY['Batam dan Kepri']::text[], 'Ya, hubungi saya', '2026-11-16 18:42:00+07'::timestamptz),
    ('BGAP-261119-S1-015', 'Rizka Nur Azizah', 'Manajer pemasaran dan penjualan', '62895603517960', 'SEMKAYAH', 'Fashion', 'Menengah', '1–10 orang', 'Excel atau spreadsheet', ARRAY['Penjualan', 'Produksi', 'Distribusi']::text[], ARRAY['Batam dan Kepri']::text[], 'Ya, hubungi saya', '2026-11-16 19:00:00+07'::timestamptz),
    ('BGAP-261119-S1-016', 'Rosdiana situmorang', 'Pemilik usaha', '6282384784438', 'Keripik  pisang kak Ross', 'Usaha kripik pisang  kakRoss', 'Menengah', '1–10 orang', 'Manual atau buku catatan', ARRAY['Keuangan']::text[], ARRAY[]::text[], 'Ya, hubungi saya', '2026-11-16 20:09:00+07'::timestamptz),
    ('BGAP-261119-S1-017', 'zulfatmawati', 'Pemilik usaha', '628136765200', 'zahwa snack', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Keuangan']::text[], ARRAY['Batam dan Kepri', 'Singapura']::text[], 'Ya, hubungi saya', '2026-11-16 20:50:00+07'::timestamptz),
    ('BGAP-261119-S1-018', 'elfiani', 'Pemilik usaha', '628127699433', 'Dapur si Kiting', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Penjualan', 'Produksi', 'Distribusi']::text[], ARRAY['Batam dan Kepri', 'Singapura']::text[], 'Ya, hubungi saya', '2026-11-16 23:18:00+07'::timestamptz),
    ('BGAP-261119-S1-019', 'Debie Anwar', 'Pemilik usaha', '6281388060007', 'PT. BERKAH CANDU ABADI', 'Makanan dan minuman', 'Menengah', '11–50 orang', 'Excel atau spreadsheet', ARRAY['Keuangan', 'Stok dan gudang', 'Ekspansi']::text[], ARRAY['Nasional', 'Singapura', 'Jepang']::text[], 'Ya, hubungi saya', '2026-11-16 23:51:00+07'::timestamptz),
    ('BGAP-261119-S1-020', 'Wahyuning Lelonowati', 'Pemilik usaha', '6281364999394', 'Unie Cathering', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Distribusi', 'SDM']::text[], ARRAY['Batam dan Kepri']::text[], 'Ya, hubungi saya', '2026-11-17 00:04:00+07'::timestamptz),
    ('BGAP-261119-S1-021', 'Rahma Dona', 'Pemilik usaha', '6282268926878', 'NANIA', 'Jasa', 'Menengah', '1–10 orang', 'Manual atau buku catatan', ARRAY['SDM']::text[], ARRAY['Batam dan Kepri', 'Nasional']::text[], 'Ya, hubungi saya', '2026-11-17 04:07:00+07'::timestamptz),
    ('BGAP-261119-S1-024', 'Dewi erawati', 'Pemilik usaha', '6285356465659', 'kYANO', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Penjualan']::text[], ARRAY['Batam dan Kepri']::text[], 'Ya, hubungi saya', '2026-11-17 04:39:00+07'::timestamptz),
    ('BGAP-261119-S1-025', 'Nonik Pustisari', 'Pemilik usaha', '62895421551555', 'd''Simple kitchen', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Pelaporan']::text[], ARRAY['Batam dan Kepri', 'Singapura']::text[], 'Ya, hubungi saya', '2026-11-17 06:30:00+07'::timestamptz),
    ('BGAP-261119-S1-026', 'Renita Agustina', 'Pemilik usaha', '6287748262820', 'Runa', 'Snack', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Penjualan']::text[], ARRAY['Batam dan Kepri', 'Nasional', 'Singapura']::text[], 'Ya, hubungi saya', '2026-11-17 07:32:00+07'::timestamptz),
    ('BGAP-261119-S1-027', 'Nadiya rahma wati', 'Pemilik usaha', '6281217533187', 'Craft &Cake', 'Craft', 'Kecil', '1–10 orang', 'Excel atau spreadsheet', ARRAY['Penjualan', 'Produksi', 'Ekspansi']::text[], ARRAY['Batam dan Kepri']::text[], 'Ya, hubungi saya', '2026-11-17 09:11:00+07'::timestamptz),
    ('BGAP-261119-S1-029', 'INDAH PURWATY', 'Pemilik usaha', '628364333791', 'Indahlicious', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Produksi']::text[], ARRAY['Batam dan Kepri']::text[], 'Belum, saya lihat dulu', '2026-11-17 17:14:00+07'::timestamptz),
    ('BGAP-261119-S1-030', 'Ahmad Fauzan Al Ghafary', 'Direktur', '62895385054428', 'Ragif Acrylic', 'Jasa', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Stok dan gudang', 'Produksi', 'Ekspansi']::text[], ARRAY['Batam dan Kepri', 'Singapura']::text[], 'Ya, hubungi saya', '2026-11-17 17:25:00+07'::timestamptz),
    ('BGAP-261119-S1-031', 'Rizaldi Abdi Razak', 'Pemilik usaha', '6281311406504', 'Dapur Bu Dina', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Keuangan', 'Stok dan gudang', 'Penjualan']::text[], ARRAY['Batam dan Kepri', 'Singapura']::text[], 'Ya, hubungi saya', '2026-11-17 17:35:00+07'::timestamptz),
    ('BGAP-261119-S1-032', 'Heri rusyanto', 'Pemilik usaha', '62815664590580', 'Eureka media', 'Manufaktur dan pengolahan', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Keuangan']::text[], ARRAY['Batam dan Kepri']::text[], 'Ya, hubungi saya', '2026-11-17 18:03:00+07'::timestamptz),
    ('BGAP-261119-S1-034', 'Budiman', 'Pemilik usaha', '6285765424521', 'CV. OPTIMUM HIJRAH MANDIRI', 'Jasa', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Keuangan', 'Penjualan', 'Distribusi']::text[], ARRAY['Batam dan Kepri']::text[], 'Ya, hubungi saya', '2026-11-18 05:59:00+07'::timestamptz),
    ('BGAP-261119-S1-037', 'ade bayu prasetyo', 'Pemilik usaha', '6281292997676', 'Barenis Batam', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Ekspansi']::text[], ARRAY['Singapura']::text[], 'Ya, hubungi saya', '2026-11-18 07:24:00+07'::timestamptz),
    ('BGAP-261119-S1-038', 'Recky Hendra S', 'Direktur', '6287718971595', 'PT. MULTITAMA INTI MADANI', 'Jasa', 'Kecil', '1–10 orang', 'Excel atau spreadsheet', ARRAY['SDM', 'Ekspansi']::text[], ARRAY['Batam dan Kepri']::text[], 'Belum, saya lihat dulu', '2026-11-18 07:33:00+07'::timestamptz),
    ('BGAP-261119-S1-039', 'Intan Meilina', 'Pemilik usaha', '628117788076', 'MG2.Snacks', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Keuangan', 'Stok dan gudang', 'Penjualan', 'Pembelian', 'Produksi', 'Distribusi', 'SDM', 'Pelaporan', 'Ekspansi']::text[], ARRAY['Batam dan Kepri']::text[], 'Ya, hubungi saya', '2026-11-18 08:39:00+07'::timestamptz),
    ('BGAP-261119-S1-040', 'Devi Fitriani', 'Pemilik usaha', '6285376275099', 'Dapur Sumando', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Excel atau spreadsheet', ARRAY['Keuangan', 'Penjualan', 'Produksi', 'Distribusi', 'Pelaporan']::text[], ARRAY['Batam dan Kepri']::text[], 'Ya, hubungi saya', '2026-11-18 08:39:00+07'::timestamptz),
    ('BGAP-261119-S2-001', 'Bima Putra Devin, S.H', 'Manajer pemasaran dan penjualan', '6281170090369', 'PT. Teratirta Batam Sejahtera', 'Industri AMDK', 'Kecil', '1–10 orang', 'Software akuntansi atau ERP', ARRAY['Distribusi', 'Ekspansi']::text[], ARRAY['Nasional', 'Singapura']::text[], 'Ya, hubungi saya', '2026-11-16 16:27:00+07'::timestamptz),
    ('BGAP-261119-S2-002', 'Siti Randuna', 'Manajer operasional', '628116667164', 'PT. Syafar Randuna wisata', 'Jasa', 'Menengah', '1–10 orang', 'Excel atau spreadsheet', ARRAY['Penjualan', 'Distribusi']::text[], ARRAY['Batam dan Kepri', 'Nasional', 'Singapura']::text[], 'Ya, hubungi saya', '2026-11-16 17:11:00+07'::timestamptz),
    ('BGAP-261119-S2-003', 'Eli Suryana', 'Pemilik usaha', '6282386794555', 'Syakira Aira', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Keuangan', 'Penjualan', 'Produksi', 'Distribusi', 'SDM']::text[], ARRAY['Batam dan Kepri', 'Nasional', 'Singapura', 'Jepang']::text[], 'Ya, hubungi saya', '2026-11-16 18:21:00+07'::timestamptz),
    ('BGAP-261119-S2-004', 'Nur sadrina rosyida', 'Pemilik usaha', '6285835667214', 'keripik pisang 2 nur,lontong sayur,gado gado', 'makanan', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Penjualan', 'Distribusi']::text[], ARRAY['Batam dan Kepri', 'Nasional', 'Singapura', 'Jepang']::text[], 'Ya, hubungi saya', '2026-11-16 18:25:00+07'::timestamptz),
    ('BGAP-261119-S2-005', 'Fitri Apriyana', 'Pemilik usaha', '6282172372129', 'Maju snack', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Keuangan', 'Penjualan', 'Produksi', 'Distribusi']::text[], ARRAY['Batam dan Kepri', 'Singapura']::text[], 'Ya, hubungi saya', '2026-11-16 18:28:00+07'::timestamptz),
    ('BGAP-261119-S2-006', 'Natasya', 'Pemilik usaha', '6285766462328', 'PT Jagung Keriting Goreng', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Keuangan', 'Stok dan gudang', 'Penjualan', 'Pembelian', 'Produksi', 'Distribusi', 'Pelaporan']::text[], ARRAY['Batam dan Kepri', 'Singapura']::text[], 'Ya, hubungi saya', '2026-11-16 18:29:00+07'::timestamptz),
    ('BGAP-261119-S2-007', 'nur adauwiyah', 'Pemilik usaha', '6282383275611', 'Kembarfood''s', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Keuangan']::text[], ARRAY['Batam dan Kepri']::text[], 'Ya, hubungi saya', '2026-11-16 18:34:00+07'::timestamptz),
    ('BGAP-261119-S2-008', 'Dina Octara', 'Pemilik usaha', '6281372224272', 'MeDina', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Penjualan', 'Produksi', 'SDM']::text[], ARRAY['Batam dan Kepri', 'Nasional']::text[], 'Ya, hubungi saya', '2026-11-16 18:49:00+07'::timestamptz),
    ('BGAP-261119-S2-009', 'Marlina Br Marbun', 'Pemilik usaha', '6289524972959', 'Cemilan Medan Lina', 'Makanan dan minuman', 'Menengah', '1–10 orang', 'Manual atau buku catatan', ARRAY['Keuangan', 'Stok dan gudang']::text[], ARRAY['Batam dan Kepri', 'Singapura']::text[], 'Ya, hubungi saya', '2026-11-16 18:57:00+07'::timestamptz),
    ('BGAP-261119-S2-010', 'Rahayu poni kis wati', 'Pemilik usaha', '62895362897020', 'Jamu tradisional', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Penjualan']::text[], ARRAY['Batam dan Kepri']::text[], 'Ya, hubungi saya', '2026-11-16 19:10:00+07'::timestamptz),
    ('BGAP-261119-S2-011', 'Kusminarni', 'Pemilik usaha', '6285271519304', 'Mama King', 'Kuliner', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Penjualan']::text[], ARRAY['Batam dan Kepri']::text[], 'Ya, hubungi saya', '2026-11-16 19:18:00+07'::timestamptz),
    ('BGAP-261119-S2-012', 'Marnetis', 'Pemilik usaha', '6282391078806', 'Dapur bu tis(serabi mini/serabi minang)', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Keuangan', 'Penjualan']::text[], ARRAY['Batam dan Kepri']::text[], 'Belum, saya lihat dulu', '2026-11-16 19:18:00+07'::timestamptz),
    ('BGAP-261119-S2-014', 'Dewi kumalasari', 'Pemilik usaha', '6282172126433', 'rengginang & bawang goreng noni', 'Manufaktur dan pengolahan', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Keuangan', 'Pelaporan']::text[], ARRAY['Batam dan Kepri']::text[], 'Ya, hubungi saya', '2026-11-16 20:05:00+07'::timestamptz),
    ('BGAP-261119-S2-017', 'Rita Yuliyati', 'Pemilik usaha', '6281333322130', 'Yulis berkah (jahe merah instan)', 'Makanan dan minuman', 'Menengah', '1–10 orang', 'Manual atau buku catatan', ARRAY['Keuangan', 'Penjualan']::text[], ARRAY['Singapura']::text[], 'Ya, hubungi saya', '2026-11-16 21:58:00+07'::timestamptz),
    ('BGAP-261119-S2-018', 'Saminah', 'Pemilik usaha', '6285643530078', 'Mbak Ina', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Penjualan', 'Distribusi']::text[], ARRAY['Batam dan Kepri', 'Singapura']::text[], 'Ya, hubungi saya', '2026-11-17 05:55:00+07'::timestamptz),
    ('BGAP-261119-S2-019', 'Rosmalina Dewi', 'Pemilik usaha', '6282172435137', 'Virnie Snack and Cookies', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Penjualan', 'Pembelian', 'Distribusi']::text[], ARRAY['Batam dan Kepri', 'Nasional', 'Singapura']::text[], 'Ya, hubungi saya', '2026-11-17 05:57:00+07'::timestamptz),
    ('BGAP-261119-S2-021', 'Raja Tri Apriani', 'Pemilik usaha', '6285271710450', 'Alkey Cookies N Co', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Keuangan']::text[], ARRAY['Nasional', 'Singapura']::text[], 'Ya, hubungi saya', '2026-11-17 06:56:00+07'::timestamptz),
    ('BGAP-261119-S2-023', 'Nur azizah', 'Pemilik usaha', '6289616032859', 'House of Devana', 'Jasa', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Pelaporan']::text[], ARRAY['Batam dan Kepri', 'Nasional', 'Singapura', 'Jepang']::text[], 'Ya, hubungi saya', '2026-11-17 07:14:00+07'::timestamptz),
    ('BGAP-261119-S2-024', 'Iis Asimah', 'Pemilik usaha', '6281276947505', 'Toko mama iis', 'Makanan dan minuman', 'Menengah', '1–10 orang', 'Manual atau buku catatan', ARRAY['Penjualan']::text[], ARRAY['Batam dan Kepri', 'Nasional']::text[], 'Ya, hubungi saya', '2026-11-17 07:29:00+07'::timestamptz),
    ('BGAP-261119-S2-025', 'Miftakhul janah', 'Pemilik usaha', '6282388050058', 'ANFATHA', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Keuangan']::text[], ARRAY['Batam dan Kepri']::text[], 'Ya, hubungi saya', '2026-11-17 08:07:00+07'::timestamptz),
    ('BGAP-261119-S2-026', 'Dyah Ayu', 'Pemilik usaha', '6282171486703', 'CV Rezeki Langgeng Abadi', 'Jasa', 'Menengah', '1–10 orang', 'Excel atau spreadsheet', ARRAY['Distribusi', 'SDM']::text[], ARRAY['Nasional']::text[], 'Belum, saya lihat dulu', '2026-11-17 09:47:00+07'::timestamptz),
    ('BGAP-261119-S2-027', 'Yosi Delvalina', 'Pemilik usaha', '6281275021705', 'Dapur Mamoci', 'Catering', 'Kecil', '1–10 orang', 'Aplikasi kasir atau POS', ARRAY['Keuangan', 'Produksi', 'SDM', 'Ekspansi']::text[], ARRAY['Nasional', 'Singapura', 'Jepang']::text[], 'Ya, hubungi saya', '2026-11-17 10:40:00+07'::timestamptz),
    ('BGAP-261119-S2-028', 'Rasinah', 'Pemilik usaha', '6289524894737', 'Jolleh', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Keuangan', 'Penjualan', 'Distribusi']::text[], ARRAY['Batam dan Kepri', 'Nasional', 'Singapura']::text[], 'Ya, hubungi saya', '2026-11-17 13:39:00+07'::timestamptz),
    ('BGAP-261119-S2-029', 'Anisa Mei', 'General manager', '62895370766801', 'PT Radisa Wisata  Bhuana', 'Jasa', 'Menengah', '11–50 orang', 'Excel atau spreadsheet', ARRAY['Penjualan', 'SDM', 'Pelaporan', 'Ekspansi']::text[], ARRAY['Batam dan Kepri', 'Nasional', 'Singapura', 'Jepang']::text[], 'Belum, saya lihat dulu', '2026-11-17 17:15:00+07'::timestamptz),
    ('BGAP-261119-S2-030', 'Titi Widiarti', 'Pemilik usaha', '6281536142050', 'Sroto & Mendoan Banyumas KENEBAE', 'Makanan dan minuman', 'Kecil', '11–50 orang', 'Excel atau spreadsheet', ARRAY['Keuangan', 'Stok dan gudang', 'SDM', 'Pelaporan']::text[], ARRAY['Batam dan Kepri']::text[], 'Ya, hubungi saya', '2026-11-18 06:15:00+07'::timestamptz),
    ('BGAP-261119-S2-031', 'Esa Yusuf', 'Manajer operasional', '6282389956535', 'PT Radisa Kreasi Boga', 'Makanan dan minuman', 'Menengah', '11–50 orang', 'Excel atau spreadsheet', ARRAY['Penjualan', 'SDM', 'Pelaporan', 'Ekspansi']::text[], ARRAY['Batam dan Kepri', 'Singapura', 'Jepang']::text[], 'Belum, saya lihat dulu', '2026-11-18 06:22:00+07'::timestamptz),
    ('BGAP-261119-S2-032', 'Yenni Hartati', 'Pemilik usaha', '6282292946895', 'Kaaliya Cake & Cookies', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Keuangan', 'Penjualan', 'Produksi', 'Ekspansi']::text[], ARRAY['Batam dan Kepri', 'Nasional', 'Singapura']::text[], 'Ya, hubungi saya', '2026-11-18 06:34:00+07'::timestamptz),
    ('BGAP-261119-S2-033', 'Kholifatul Hasanah', 'Manajer pemasaran dan penjualan', '6281274171347', 'Alkey Cookies n Co', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Distribusi']::text[], ARRAY['Batam dan Kepri', 'Nasional', 'Singapura']::text[], 'Ya, hubungi saya', '2026-11-18 07:12:00+07'::timestamptz),
    ('BGAP-261119-S2-034', 'Julia siscawaty', 'Pemilik usaha', '6282392276051', 'D''Buika', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Keuangan', 'Penjualan']::text[], ARRAY[]::text[], 'Ya, hubungi saya', '2026-11-18 07:30:00+07'::timestamptz),
    ('BGAP-261119-S2-035', 'Mardiah', 'Pemilik usaha', '6289678572872', 'Loundry', 'Usaha setrika uap', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Keuangan', 'Pembelian']::text[], ARRAY[]::text[], 'Ya, hubungi saya', '2026-11-18 07:38:00+07'::timestamptz),
    ('BGAP-261119-S2-036', 'Dian Fitri Anggraini', 'Pemilik usaha', '6289521277030', 'DIFIAN', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Manual atau buku catatan', ARRAY['Penjualan']::text[], ARRAY['Batam dan Kepri']::text[], 'Ya, hubungi saya', '2026-11-18 07:58:00+07'::timestamptz),
    ('BGAP-261119-S2-037', 'Rika Vidyasari', 'Pemilik usaha', '6281374712623', 'YOUIDN PARFUM', 'Parfum', 'Kecil', '1–10 orang', 'Excel atau spreadsheet', ARRAY['Ekspansi']::text[], ARRAY['Batam dan Kepri', 'Nasional']::text[], 'Ya, hubungi saya', '2026-11-18 08:01:00+07'::timestamptz),
    ('BGAP-261119-S2-038', 'Suko Rini', 'Pemilik usaha', '6281991024170', 'Ipunk snack', 'Makanan dan minuman', 'Kecil', '1–10 orang', 'Excel atau spreadsheet', ARRAY['Produksi', 'Distribusi', 'Pelaporan']::text[], ARRAY['Batam dan Kepri']::text[], 'Ya, hubungi saya', '2026-11-18 09:16:00+07'::timestamptz)
)
insert into public.registrations (
  kode,
  sesi,
  nomor,
  nama,
  jabatan,
  wa,
  usaha,
  bidang,
  skala,
  tk,
  sistem,
  butuh,
  pasar,
  minat,
  status,
  wa_sent_at,
  created_at
)
select
  r.kode,
  1 as sesi,
  b.max_no + row_number() over () as nomor,
  r.nama,
  r.jabatan,
  r.wa,
  r.usaha,
  r.bidang,
  r.skala,
  r.tk,
  r.sistem,
  r.butuh,
  r.pasar,
  r.minat,
  'disetujui' as status,
  now() as wa_sent_at,
  r.created_at
from raw_data r
cross join v_base b
on conflict (kode) do update set
  status = 'disetujui',
  wa_sent_at = coalesce(public.registrations.wa_sent_at, now()),
  nama = excluded.nama,
  jabatan = excluded.jabatan,
  wa = excluded.wa,
  usaha = excluded.usaha,
  bidang = excluded.bidang,
  skala = excluded.skala,
  tk = excluded.tk,
  sistem = excluded.sistem,
  butuh = excluded.butuh,
  pasar = excluded.pasar,
  minat = excluded.minat;

-- Verifikasi hasil impor
select count(*) as total_disetujui, count(wa_sent_at) as total_wa_terbuka 
from public.registrations 
where status = 'disetujui';
