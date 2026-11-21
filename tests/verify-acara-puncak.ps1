$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$failures = @()
function Assert-Contains($path, $pattern, $label) {
  $text = Get-Content -Raw -LiteralPath (Join-Path $root $path)
  if ($text -notmatch [regex]::Escape($pattern)) { $script:failures += "$label : '$pattern' tidak ada di $path" }
}
function Assert-NotContains($path, $pattern, $label) {
  $text = Get-Content -Raw -LiteralPath (Join-Path $root $path)
  if ($text -match [regex]::Escape($pattern)) { $script:failures += "$label : '$pattern' masih ada di $path" }
}

Assert-Contains 'index.html' 'dKode' 'form kode registrasi'
Assert-Contains 'index.html' 'PENDAFTARAN_DITUTUP' 'form pesan ditutup'
Assert-Contains 'index.html' 'd.dibuka' 'form baca sakelar'
Assert-Contains 'index.html' 'Download PDF' 'form tombol unduh pdf'
Assert-Contains 'index.html' 'Join grup WhatsApp peserta' 'form tombol join grup'

Assert-Contains 'dashboard.html' 'peserta terpilih' 'dashboard peserta terpilih'
Assert-NotContains 'dashboard.html' 'dari kuota 80' 'dashboard tanpa kuota 80'
Assert-Contains 'dashboard.html' 'Setujui' 'dashboard tombol setujui'
Assert-Contains 'dashboard.html' 'Menunggu' 'dashboard status'
Assert-Contains 'dashboard.html' 'Harmoni One' 'dashboard tempat'
Assert-Contains 'dashboard.html' 'maps.google.com' 'dashboard gps'
Assert-NotContains 'dashboard.html' 'Golden View' 'dashboard tanpa golden view'
Assert-NotContains 'dashboard.html' 'MAIL_URL' 'dashboard tanpa apps script email'
Assert-NotContains 'dashboard.html' '["Email"' 'dashboard excel tanpa email'
Assert-Contains 'dashboard.html' 'wa.me' 'dashboard WA'
Assert-Contains 'dashboard.html' 'set_pendaftaran' 'dashboard sakelar'
Assert-Contains 'dashboard.html' 'Tutup pendaftaran' 'dashboard tombol tutup'
Assert-Contains 'index.html' 'TUTUP=false' 'form dibuka'
Assert-Contains 'dashboard.html' 'DASHBOARD_DITUTUP=false' 'dashboard dibuka'
Assert-Contains 'login.html' 'LOGIN_DITUTUP=false' 'login dibuka'
Assert-NotContains 'dashboard.html' 'Sesi Pagi' 'dashboard sesi lama'
Assert-NotContains 'dashboard.html' '19 November 2026' 'dashboard tanggal lama'

Assert-Contains 'supabase/2026-11-18-acara-puncak.sql' 'KUOTA_PENUH' 'sql kuota penuh'
Assert-Contains 'supabase/2026-11-18-acara-puncak.sql' 'drop function if exists public.kuota_sesi()' 'sql drop kuota lama'
Assert-Contains 'supabase/2026-11-18-acara-puncak.sql' 'ticket_payload' 'sql rpc tiket'
Assert-Contains 'supabase/2026-11-18-acara-puncak.sql' 'set_status' 'sql rpc approval'
Assert-Contains 'supabase/2026-11-18-acara-puncak.sql' 'menunggu' 'sql status default'
Assert-NotContains 'supabase/2026-11-18-acara-puncak.sql' 'drop column' 'sql destruktif'

Assert-Contains 'supabase/2026-11-20-unlimited-quota.sql' 'PENDAFTARAN_DITUTUP' 'sql sakelar pendaftaran'
Assert-NotContains 'supabase/2026-11-20-unlimited-quota.sql' 'KUOTA_PENUH' 'sql tanpa kuota statis 80'
Assert-Contains 'apps-script/Code.gs' 'doGet' 'apps script endpoint'
Assert-Contains 'apps-script/Code.gs' 'GmailApp.sendEmail' 'apps script email'
Assert-NotContains 'apps-script/Code.gs' 'application/pdf' 'apps script tanpa pdf'
Assert-Contains 'apps-script/Code.gs' 'Screenshot email ini' 'instruksi screenshot di email'
Assert-Contains 'apps-script/Code.gs' 'SUPABASE_SERVICE_KEY' 'apps script service key'
Assert-Contains 'apps-script/Code.gs' 'Terima kasih,' 'desain sapaan pdf'
Assert-Contains 'apps-script/Code.gs' 'Kode pendaftaran' 'desain kode tiket pdf'
Assert-Contains 'apps-script/Code.gs' 'Join grup WhatsApp peserta' 'desain tombol wa pdf'
Assert-Contains 'apps-script/Code.gs' '@media only screen and (max-width:480px)' 'desain responsif hp'
Assert-Contains 'apps-script/Code.gs' 'word-break:break-word' 'desain teks tidak overflow'
Assert-Contains 'apps-script/Code.gs' 'Panitia - hubungi bila ada kendala' 'desain panitia pdf'
Assert-Contains 'supabase/2026-11-18-acara-puncak.sql' "kode like 'BGAP-%'" 'sql filter event baru'
Assert-Contains 'supabase/2026-11-18-acara-puncak.sql' 'nomor, wa, email' 'sql kolom nomor lama'
Assert-Contains 'supabase/2026-11-18-acara-puncak.sql' 'event_settings' 'sql tabel sakelar'
Assert-Contains 'supabase/2026-11-18-acara-puncak.sql' 'set_pendaftaran' 'sql rpc sakelar'
Assert-Contains 'supabase/2026-11-18-acara-puncak.sql' 'PENDAFTARAN_DITUTUP' 'sql tolak saat ditutup'
Assert-Contains 'supabase/2026-11-18-acara-puncak.sql' 'dibuka boolean' 'sql status dibuka'
Assert-Contains 'apps-script/README.md' 'Anyone' 'apps script panduan deploy'

if ($failures.Count) {
  Write-Output "FAIL ($($failures.Count))"
  $failures | ForEach-Object { Write-Output "  - $_" }
  exit 1
}
Write-Output 'PASS - semua pemeriksaan Acara Puncak lolos'
