-- =====================================================================
-- Acara Puncak Business Growth & Digital Readiness Forum Batam 2026
-- 27 November 2026 · 14.00-17.00 WIB · Hotel Golden View Batam
-- Kuota: 80 peserta (satu sesi)
--
-- CARA PAKAI: paste seluruh isi file ini ke Supabase SQL Editor, lalu Run.
-- File ini AMAN dijalankan ulang (additive + create or replace).
-- =====================================================================

-- 1. Kolom baru (tidak ada kolom lama yang dihapus/diubah)
alter table public.registrations add column if not exists email text;
alter table public.registrations add column if not exists status text not null default 'menunggu';
alter table public.registrations add column if not exists wa_sent_at timestamptz;
alter table public.registrations add column if not exists email_sent_at timestamptz;

-- 2. Constraint status (dibuat hanya jika belum ada)
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'registrations_status_check'
      and conrelid = 'public.registrations'::regclass
  ) then
    alter table public.registrations
      add constraint registrations_status_check
      check (status in ('menunggu', 'disetujui', 'ditolak'));
  end if;
end $$;

-- 3. Sakelar pendaftaran (bisa diubah dari dashboard)
create table if not exists public.event_settings (
  kunci text primary key,
  nilai boolean not null default true
);
insert into public.event_settings (kunci, nilai)
values ('pendaftaran_dibuka', true)
on conflict (kunci) do nothing;

-- 4. Submit pendaftaran: satu sesi, kuota 80, status awal menunggu
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

  -- Normalisasi WA: terima 08..., 8..., +62..., 62..., 6208... -> 628...
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
  if v_count >= 80 then
    raise exception 'KUOTA_PENUH';
  end if;

  -- nomor bersama sesi unik, jadi lanjut dari nilai maksimum yang sudah ada
  select coalesce(max(nomor), 0) + 1 into v_nomor from public.registrations;

  v_kode := 'BGAP-'
            || to_char(now() at time zone 'Asia/Jakarta', 'YYMMDD')
            || '-' || lpad((v_count + 1)::text, 3, '0')
            || '-' || upper(substr(md5(random()::text), 1, 4));

  insert into public.registrations
    (kode, sesi, nama, jabatan, nomor, wa, email, usaha, bidang, skala, tk,
     sistem, butuh, pasar, minat, status)
  values
    (v_kode, 1, p->>'nama', p->>'jabatan', v_nomor, v_wa, p->>'email',
     p->>'usaha', p->>'bidang', p->>'skala', p->>'tk', p->>'sistem',
     (select coalesce(array_agg(value), '{}'::text[]) from jsonb_array_elements_text(coalesce(p->'butuh', '[]'::jsonb))),
     (select coalesce(array_agg(value), '{}'::text[]) from jsonb_array_elements_text(coalesce(p->'pasar', '[]'::jsonb))),
     p->>'minat', 'menunggu');

  return v_kode;
end;
$$;

-- 5. Kuota satu sesi + status sakelar pendaftaran
-- Return type berubah dari (sesi, terisi, kuota) menjadi (kuota, terisi, sisa, dibuka),
-- sehingga harus di-drop dulu (CREATE OR REPLACE tidak bisa mengubah return type).
drop function if exists public.kuota_sesi();

create or replace function public.kuota_sesi()
returns table(kuota int, terisi int, sisa int, dibuka boolean)
language sql
stable
security definer
set search_path = public
as $$
  select 80,
         count(*)::int,
         case when coalesce((select nilai from public.event_settings where kunci = 'pendaftaran_dibuka'), true)
              then greatest(80 - count(*)::int, 0) else 0 end,
         coalesce((select nilai from public.event_settings where kunci = 'pendaftaran_dibuka'), true)
  from public.registrations
  where kode like 'BGAP-%';
$$;

-- 5. Approval panitia
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

-- 6. Payload tiket untuk Apps Script (hanya yang sudah disetujui)
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

-- 7. Penanda WA / email sudah dikirim (idempoten)
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

-- 8. Sakelar buka/tutup pendaftaran (hanya panitia yang terautentikasi)
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

-- 9. Hak akses
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
