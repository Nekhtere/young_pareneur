-- =====================================================================
-- SETUP DARI NOL — Project Supabase baru
-- Project: https://sfnguqjpjcwdlpydelhk.supabase.co
-- Acara Puncak Business Growth & Digital Readiness Forum Batam 2026
-- 27 November 2026 · 14.00-17.00 WIB · Hotel Golden View Batam
-- Kuota: 80 peserta, satu sesi, status awal menunggu.
--
-- CARA PAKAI:
-- 1. Paste seluruh isi file ini ke Supabase SQL Editor project BARU -> Run.
-- 2. Jalankan: insert into public.admin_emails(email) values ('EMAIL_GOOGLE_KAMU@gmail.com');
-- 3. Authentication -> Providers -> aktifkan Google, isi Client ID/Secret.
-- 4. Authentication -> URL Configuration:
--      Site URL      = https://< url vercel kamu >
--      Redirect URLs = https://< url vercel kamu >/**
-- 5. Di Google Cloud Console -> OAuth client, tambahkan Authorized redirect URI:
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
  status text not null default 'menunggu',
  wa_sent_at timestamptz,
  email_sent_at timestamptz,
  constraint registrations_sesi_nomor_key unique (sesi, nomor),
  constraint registrations_status_check check (status in ('menunggu', 'disetujui', 'ditolak'))
);

-- ---------- 2. RLS ----------
alter table public.registrations enable row level security;

drop policy if exists "panitia_baca_pendaftar" on public.registrations;
create policy "panitia_baca_pendaftar" on public.registrations
  for select to authenticated using (true);

drop policy if exists "panitia_hapus_pendaftar" on public.registrations;
create policy "panitia_hapus_pendaftar" on public.registrations
  for delete to authenticated using (true);

grant select, delete on public.registrations to authenticated;

-- ---------- 3. DAFTAR EMAIL ADMIN ----------
create table if not exists public.admin_emails (
  email text primary key
);
alter table public.admin_emails enable row level security;

-- ---------- 4. SAKELAR PENDAFTARAN ----------
create table if not exists public.event_settings (
  kunci text primary key,
  nilai boolean not null default true
);
insert into public.event_settings (kunci, nilai)
values ('pendaftaran_dibuka', true)
on conflict (kunci) do nothing;

-- ---------- 5. CEK ADMIN ----------
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

-- ---------- 6. SUBMIT PENDAFTARAN ----------
create or replace function public.submit_registration(p jsonb)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
  v_nomor int;
  v_kode text;
  v_wa text;
begin
  if not coalesce((select nilai from public.event_settings where kunci = 'pendaftaran_dibuka'), true) then
    raise exception 'PENDAFTARAN_DITUTUP';
  end if;

  -- Normalisasi WA: 08..., 8..., +62..., 62..., 6208... -> 628...
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

  select count(*) into v_count from public.registrations where kode like 'BGAP-%';
  if v_count >= 24 then
    raise exception 'KUOTA_PENUH';
  end if;

  select coalesce(max(nomor), 0) + 1 into v_nomor from public.registrations;

  v_kode := 'BGAP-'
            || to_char(now() at time zone 'Asia/Jakarta', 'YYMMDD')
            || '-' || lpad((v_count + 1)::text, 3, '0')
            || '-' || upper(substr(md5(random()::text), 1, 4));

  insert into public.registrations
    (kode, sesi, nomor, nama, jabatan, wa, email, usaha, bidang, skala, tk,
     sistem, butuh, pasar, minat, status)
  values
    (v_kode, 1, v_nomor, p->>'nama', p->>'jabatan', v_wa, p->>'email',
     p->>'usaha', p->>'bidang', p->>'skala', p->>'tk', p->>'sistem',
     (select coalesce(array_agg(value), '{}'::text[]) from jsonb_array_elements_text(coalesce(p->'butuh', '[]'::jsonb))),
     (select coalesce(array_agg(value), '{}'::text[]) from jsonb_array_elements_text(coalesce(p->'pasar', '[]'::jsonb))),
     p->>'minat', 'menunggu');

  return v_kode;
end;
$$;

-- ---------- 7. KUOTA + STATUS SAKELAR ----------
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
  where kode like 'BGAP-%';
$$;

-- ---------- 8. APPROVAL ----------
create or replace function public.set_status(p_id text, p_status text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_status not in ('disetujui', 'ditolak') then
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

-- ---------- 9. PAYLOAD TIKET UNTUK APPS SCRIPT ----------
create or replace function public.ticket_payload(p_kode text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select case when status = 'disetujui' then jsonb_build_object(
    'kode', kode,
    'nama', nama,
    'jabatan', jabatan,
    'wa', wa,
    'email', email,
    'usaha', usaha,
    'bidang', bidang,
    'tanggal', 'Jumat, 27 November 2026',
    'waktu', '14.00-17.00 WIB',
    'tempat', 'Hotel Golden View Batam'
  ) else null end
  from public.registrations
  where kode = p_kode
  limit 1;
$$;

-- ---------- 10. SAKELAR BUKA/TUTUP ----------
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

-- ---------- 11. HAK AKSES ----------
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

-- ---------- 12. BUCKET UNTUK LOGO (opsional) ----------
insert into storage.buckets (id, name, public)
values ('assets', 'assets', true)
on conflict (id) do nothing;
