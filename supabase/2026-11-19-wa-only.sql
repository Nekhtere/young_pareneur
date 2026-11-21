-- =====================================================================
-- Acara Puncak Business Growth & Digital Readiness Forum Batam 2026
-- Migrasi: Hapus Kolom Email & Penyesuaian WhatsApp-Only
-- Tanggal: 19 November 2026
--
-- CARA PAKAI:
-- Salin dan jalankan seluruh isi file ini di Supabase SQL Editor.
-- =====================================================================

-- 1. Hapus kolom email dan email_sent_at secara fisik dari tabel registrations
alter table public.registrations drop column if exists email;
alter table public.registrations drop column if exists email_sent_at;

-- 2. Perbarui RPC submit_registration tanpa kolom email
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

  -- Nomor urut bersama unik
  select coalesce(max(nomor), 0) + 1 into v_nomor from public.registrations;

  v_kode := 'BGAP-'
            || to_char(now() at time zone 'Asia/Jakarta', 'YYMMDD')
            || '-' || lpad((v_count + 1)::text, 3, '0')
            || '-' || upper(substr(md5(random()::text), 1, 4));

  insert into public.registrations
    (kode, sesi, nama, jabatan, nomor, wa, usaha, bidang, skala, tk,
     sistem, butuh, pasar, minat, status)
  values
    (v_kode, 1, p->>'nama', p->>'jabatan', v_nomor, v_wa,
     p->>'usaha', p->>'bidang', p->>'skala', p->>'tk', p->>'sistem',
     (select coalesce(array_agg(value), '{}'::text[]) from jsonb_array_elements_text(coalesce(p->'butuh', '[]'::jsonb))),
     (select coalesce(array_agg(value), '{}'::text[]) from jsonb_array_elements_text(coalesce(p->'pasar', '[]'::jsonb))),
     p->>'minat', 'menunggu');

  return v_kode;
end;
$$;

-- 3. Perbarui RPC mark_sent hanya untuk tracking WhatsApp
create or replace function public.mark_sent(p_id text, p_kind text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_kind = 'wa' then
    update public.registrations set wa_sent_at = coalesce(wa_sent_at, now()) where id::text = p_id;
  else
    raise exception 'KIND_INVALID';
  end if;
  return found;
end;
$$;

-- 4. Hapus RPC ticket_payload lama karena Apps Script / email sudah tidak dipakai
drop function if exists public.ticket_payload(text);

-- 5. Hak akses eksekusi
revoke all on function public.submit_registration(jsonb) from public, anon, authenticated;
revoke all on function public.mark_sent(text, text) from public, anon, authenticated;

grant execute on function public.submit_registration(jsonb) to anon, authenticated;
grant execute on function public.mark_sent(text, text) to authenticated;
