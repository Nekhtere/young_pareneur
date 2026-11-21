-- =====================================================================
-- YOUNGPRENEUR KEPRI 2026 - SQL lengkap (copas ke Supabase > SQL Editor > Run)
-- Kuota 24 slot. Aman dijalankan ulang. Tidak menyentuh tabel Forum Batam.
-- =====================================================================

-- 1. Cek admin: dipakai kalau belum ada fungsi is_admin() dari dashboard lama.
--    Kalau sudah ada, fungsi lama TIDAK diubah.
do $$
begin
  if to_regprocedure('public.is_admin()') is null then
    create table if not exists public.admin_emails (email text primary key);
    alter table public.admin_emails enable row level security;
    execute $f$
      create function public.is_admin() returns boolean
      language sql stable security definer set search_path = public as
      $b$ select exists (select 1 from public.admin_emails
                         where lower(email) = lower(coalesce(auth.jwt() ->> 'email',''))) $b$
    $f$;
  end if;
end $$;
-- Hanya jika is_admin() baru dibuat di atas, daftarkan email admin kamu:
-- insert into public.admin_emails (email) values ('emailkamu@gmail.com') on conflict do nothing;

-- 2. Konfigurasi (kuota + buka/tutup)
create table if not exists public.youngpreneur_config (
  id     int primary key check (id = 1),
  kuota  int not null default 24 check (kuota >= 0),
  dibuka boolean not null default true
);
insert into public.youngpreneur_config (id, kuota, dibuka) values (1, 24, true)
on conflict (id) do update set kuota = 24;

-- 3. Tabel peserta
create sequence if not exists public.ypk_seq;

create table if not exists public.youngpreneur_peserta (
  id         bigint generated always as identity primary key,
  kode       text   not null unique,
  nama       text   not null,
  status     text   not null,
  wa         text   not null unique,
  institusi  text   not null,
  jurusan    text   not null,
  tingkat    text   not null,
  ide        text   not null,
  created_at timestamptz not null default now()
);
-- Bersihkan kolom dari versi SQL sebelumnya (jika sempat dijalankan)
alter table public.youngpreneur_peserta drop column if exists bidang;
alter table public.youngpreneur_peserta drop column if exists harapan;
alter table public.youngpreneur_peserta drop column if exists lanjut;

-- 4. RLS: aktif, tanpa akses publik. Pendaftar hanya lewat fungsi submit.
alter table public.youngpreneur_peserta enable row level security;
alter table public.youngpreneur_config  enable row level security;

drop policy if exists ypk_peserta_admin_select on public.youngpreneur_peserta;
drop policy if exists ypk_peserta_admin_delete on public.youngpreneur_peserta;
create policy ypk_peserta_admin_select on public.youngpreneur_peserta
  for select to authenticated using (public.is_admin());
create policy ypk_peserta_admin_delete on public.youngpreneur_peserta
  for delete to authenticated using (public.is_admin());
-- youngpreneur_config: tanpa policy = tertutup; diakses lewat fungsi saja.

revoke all on public.youngpreneur_peserta from anon, authenticated;
revoke all on public.youngpreneur_config  from anon, authenticated;
grant select, delete on public.youngpreneur_peserta to authenticated;

-- 5. Info kuota (publik, hanya angka)
drop function if exists public.kuota_youngpreneur();
create function public.kuota_youngpreneur()
returns table (kuota int, terisi int, sisa int, dibuka boolean)
language sql stable security definer set search_path = public as $$
  select c.kuota,
         (select count(*)::int from public.youngpreneur_peserta),
         greatest(c.kuota - (select count(*)::int from public.youngpreneur_peserta), 0),
         c.dibuka
  from public.youngpreneur_config c where c.id = 1;
$$;

-- 6. Kirim pendaftaran (publik, divalidasi di server, anti-race kuota)
create or replace function public.submit_youngpreneur(p jsonb)
returns text
language plpgsql security definer set search_path = public as $$
declare
  v_wa   text := regexp_replace(coalesce(p->>'wa',''), '\D', '', 'g');
  v_kode text;
  v_cfg  public.youngpreneur_config;
begin
  perform pg_advisory_xact_lock(hashtext('ypk_submit'));

  select * into v_cfg from public.youngpreneur_config where id = 1;
  if not found or not v_cfg.dibuka then raise exception 'PENDAFTARAN_DITUTUP'; end if;

  if v_wa !~ '^62[0-9]{8,13}$' then raise exception 'WA_INVALID'; end if;
  if length(trim(coalesce(p->>'nama',''))) < 3
     or length(trim(coalesce(p->>'institusi',''))) < 3
     or length(trim(coalesce(p->>'jurusan',''))) < 2
     or length(trim(coalesce(p->>'tingkat',''))) < 1
     or length(p::text) > 2000
     or coalesce(p->>'status','') not in ('Mahasiswa','Siswa/i SMK')
     or coalesce(p->>'ide','') not in ('Sudah punya usaha','Belum punya usaha, tapi tertarik')
  then raise exception 'DATA_TIDAK_VALID'; end if;

  if exists (select 1 from public.youngpreneur_peserta where wa = v_wa) then
    raise exception 'SUDAH_TERDAFTAR';
  end if;
  if (select count(*) from public.youngpreneur_peserta) >= v_cfg.kuota then
    raise exception 'KUOTA_PENUH';
  end if;

  v_kode := 'YPK-' || lpad(nextval('public.ypk_seq')::text, 4, '0');
  insert into public.youngpreneur_peserta (kode, nama, status, wa, institusi, jurusan, tingkat, ide)
  values (v_kode, trim(p->>'nama'), p->>'status', v_wa,
          trim(p->>'institusi'), trim(p->>'jurusan'), left(trim(p->>'tingkat'), 30), p->>'ide');
  return v_kode;
end;
$$;

-- 7. Buka/tutup pendaftaran (khusus admin)
create or replace function public.set_pendaftaran_youngpreneur(p_buka boolean)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  update public.youngpreneur_config set dibuka = p_buka where id = 1;
end;
$$;

-- 8. Hak eksekusi fungsi
revoke all on function public.kuota_youngpreneur()                 from public;
revoke all on function public.submit_youngpreneur(jsonb)           from public;
revoke all on function public.set_pendaftaran_youngpreneur(boolean) from public;
grant execute on function public.kuota_youngpreneur()       to anon, authenticated;
grant execute on function public.submit_youngpreneur(jsonb) to anon, authenticated;
grant execute on function public.set_pendaftaran_youngpreneur(boolean) to authenticated;

-- 9. Cek hasil (opsional)
-- select * from public.kuota_youngpreneur();
-- select tablename, rowsecurity from pg_tables where tablename like 'youngpreneur%';
