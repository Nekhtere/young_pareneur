-- =====================================================================
-- SETUP DARI NOL — SISTEM INSTAN (SIAPA CEPAT DIA DAPAT)
-- Project: https://sfnguqjpjcwdlpydelhk.supabase.co
-- Sistem pendaftaran langsung terkonfirmasi (status disetujui otomatis)
-- Kuota: 24 peserta (siapa cepat dia dapat)
--
-- CARA PAKAI:
-- 1. Buka Supabase Dashboard > SQL Editor > New query.
-- 2. Paste seluruh isi file ini -> Klik RUN.
-- 3. Daftarkan email Google panitia:
--      insert into public.admin_emails(email) values ('EMAIL_GOOGLE_KAMU@gmail.com');
-- 4. Authentication -> Providers -> aktifkan Google, isi Client ID & Secret.
-- 5. Authentication -> URL Configuration:
--      Site URL      = URL hosting pendaftaran kamu
--      Redirect URLs = URL hosting kamu/**
-- 6. Google Cloud Console -> OAuth Client, tambahkan Authorized redirect URI:
--      https://sfnguqjpjcwdlpydelhk.supabase.co/auth/v1/callback
-- =====================================================================

-- ---------- 1. TABEL PENDAFTAR ----------
create table if not exists public.registrations (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  kode text not null unique,
  sesi integer not null default 1,
  nomor integer not null,
  nama text not null,
  jabatan text,
  wa text,
  email text,
  usaha text,
  bidang text,
  skala text,
  tk text,
  sistem text,
  butuh text[],
  pasar text[],
  minat text,
  status text not null default 'disetujui',
  wa_sent_at timestamptz,
  email_sent_at timestamptz,
  constraint registrations_sesi_nomor_key unique (sesi, nomor),
  constraint registrations_status_check check (status in ('disetujui', 'ditolak', 'menunggu'))
);

-- ---------- 2. RLS (ROW LEVEL SECURITY) ----------
alter table public.registrations enable row level security;

drop policy if exists "panitia_baca_pendaftar" on public.registrations;
create policy "panitia_baca_pendaftar" on public.registrations
  for select to authenticated using (true);

drop policy if exists "panitia_update_pendaftar" on public.registrations;
create policy "panitia_update_pendaftar" on public.registrations
  for update to authenticated using (true);

drop policy if exists "panitia_hapus_pendaftar" on public.registrations;
create policy "panitia_hapus_pendaftar" on public.registrations
  for delete to authenticated using (true);

grant select, update, delete on public.registrations to authenticated;

-- ---------- 3. DAFTAR EMAIL ADMIN / PANITIA ----------
create table if not exists public.admin_emails (
  email text primary key
);
alter table public.admin_emails enable row level security;

drop policy if exists "panitia_baca_admin_emails" on public.admin_emails;
create policy "panitia_baca_admin_emails" on public.admin_emails
  for select to authenticated using (true);

grant select on public.admin_emails to authenticated;

-- ---------- 4. SAKELAR PENDAFTARAN ----------
create table if not exists public.event_settings (
  kunci text primary key,
  nilai boolean not null default true
);

insert into public.event_settings (kunci, nilai)
values ('pendaftaran_dibuka', true)
on conflict (kunci) do nothing;

alter table public.event_settings enable row level security;

drop policy if exists "publik_baca_settings" on public.event_settings;
create policy "publik_baca_settings" on public.event_settings
  for select to anon, authenticated using (true);

grant select on public.event_settings to anon, authenticated;

-- ---------- 5. CEK ADMIN LOGIN ----------
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists(
    select 1 from public.admin_emails
    where lower(email) = lower(coalesce(auth.jwt()->>'email', ''))
  );
$$;
revoke all on function public.is_admin() from public, anon, authenticated;
grant execute on function public.is_admin() to authenticated;

-- ---------- 6. SUBMIT PENDAFTARAN (LANGSUNG TERKONFIRMASI) ----------
create or replace function public.submit_registration(p jsonb)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  c_kuota constant int := 24; -- Batas kuota pendaftaran (24 slot)
  v_count int;
  v_nomor int;
  v_kode text;
  v_wa text;
begin
  -- 1. Cek sakelar buka/tutup pendaftaran
  if not coalesce((select nilai from public.event_settings where kunci = 'pendaftaran_dibuka'), true) then
    raise exception 'PENDAFTARAN_DITUTUP';
  end if;

  -- 2. Normalisasi nomor WhatsApp
  v_wa := regexp_replace(coalesce(p->>'wa', ''), '\D', '', 'g');
  if left(v_wa, 1) = '0' then
    v_wa := '62' || substring(v_wa from 2);
  elsif left(v_wa, 1) = '8' then
    v_wa := '62' || v_wa;
  elsif left(v_wa, 3) = '620' then
    v_wa := '62' || substring(v_wa from 4);
  end if;
  if v_wa !~ '^62[0-9]{8,13}$' then
    raise exception 'WA_INVALID';
  end if;

  -- 3. Cek kuota: siapa cepat dia dapat (hanya hitung pendaftar yang tidak ditolak)
  select count(*) into v_count from public.registrations where status != 'ditolak';
  if v_count >= c_kuota then
    raise exception 'KUOTA_PENUH';
  end if;

  -- 4. Nomor urut peserta
  select coalesce(max(nomor), 0) + 1 into v_nomor from public.registrations;

  -- 5. Generate kode unik pendaftaran
  v_kode := 'BGAP-'
            || to_char(now() at time zone 'Asia/Jakarta', 'YYMMDD')
            || '-' || lpad((v_nomor)::text, 3, '0')
            || '-' || upper(substr(md5(random()::text), 1, 4));

  -- 6. Insert data — STATUS LANGSUNG 'disetujui' (langsung aktif)
  insert into public.registrations
    (kode, sesi, nomor, nama, jabatan, wa, email, usaha, bidang, skala, tk,
     sistem, butuh, pasar, minat, status)
  values
    (v_kode, 1, v_nomor, p->>'nama', p->>'jabatan', v_wa, p->>'email',
     p->>'usaha', p->>'bidang', p->>'skala', p->>'tk', p->>'sistem',
     (select coalesce(array_agg(value), '{}'::text[]) from jsonb_array_elements_text(coalesce(p->'butuh', '[]'::jsonb))),
     (select coalesce(array_agg(value), '{}'::text[]) from jsonb_array_elements_text(coalesce(p->'pasar', '[]'::jsonb))),
     p->>'minat', 'disetujui');

  return v_kode;
end;
$$;

-- ---------- 7. INFORMASI KUOTA & STATUS DIBUKA ----------
drop function if exists public.kuota_sesi();

create or replace function public.kuota_sesi()
returns table(kuota int, terisi int, sisa int, dibuka boolean)
language sql
stable
security definer
set search_path = public
as $$
  select 24,
         count(*)::int,
         case when coalesce((select nilai from public.event_settings where kunci = 'pendaftaran_dibuka'), true)
              then greatest(24 - count(*)::int, 0) else 0 end,
         coalesce((select nilai from public.event_settings where kunci = 'pendaftaran_dibuka'), true)
  from public.registrations
  where status != 'ditolak';
$$;

-- ---------- 8. MANAJEMEN STATUS & TRACKING (UNTUK DASHBOARD) ----------
create or replace function public.set_status(p_id text, p_status text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_status not in ('disetujui', 'ditolak', 'menunggu') then
    raise exception 'STATUS_INVALID';
  end if;
  update public.registrations set status = p_status where id::text = p_id;
  return found;
end;
$$;

create or replace function public.mark_sent(p_id text, p_kind text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_kind = 'wa' then
    update public.registrations set wa_sent_at = coalesce(wa_sent_at, now()) where id::text = p_id;
  elsif p_kind = 'email' then
    update public.registrations set email_sent_at = coalesce(email_sent_at, now()) where id::text = p_id;
  else
    raise exception 'KIND_INVALID';
  end if;
  return found;
end;
$$;

-- ---------- 9. PAYLOAD TIKET (UNTUK CETAK / APPS SCRIPT) ----------
create or replace function public.ticket_payload(p_kode text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'kode', kode,
    'nama', nama,
    'jabatan', jabatan,
    'wa', wa,
    'email', email,
    'usaha', usaha,
    'bidang', bidang,
    'tanggal', 'Jumat, 27 November 2026',
    'waktu', '13.30-17.00 WIB',
    'tempat', 'Harmoni One Convention Hotel & Service Apartments, Batam Centre'
  )
  from public.registrations
  where kode = p_kode and status = 'disetujui'
  limit 1;
$$;

-- ---------- 10. SAKELAR BUKA/TUTUP DARI DASHBOARD ----------
create or replace function public.set_pendaftaran(p_buka boolean)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.event_settings set nilai = p_buka where kunci = 'pendaftaran_dibuka';
  return found;
end;
$$;

-- ---------- 11. HAK AKSES FUNGSI (PERMISSIONS) ----------
revoke all on function public.submit_registration(jsonb) from public, anon, authenticated;
revoke all on function public.kuota_sesi() from public, anon, authenticated;
revoke all on function public.set_status(text, text) from public, anon, authenticated;
revoke all on function public.ticket_payload(text) from public, anon, authenticated;
revoke all on function public.mark_sent(text, text) from public, anon, authenticated;
revoke all on function public.set_pendaftaran(boolean) from public, anon, authenticated;

grant execute on function public.submit_registration(jsonb) to anon, authenticated;
grant execute on function public.kuota_sesi() to anon, authenticated;
grant execute on function public.ticket_payload(text) to service_role, authenticated;
grant execute on function public.set_status(text, text) to authenticated;
grant execute on function public.mark_sent(text, text) to authenticated;
grant execute on function public.set_pendaftaran(boolean) to authenticated;
