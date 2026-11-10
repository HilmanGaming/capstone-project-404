-- A. Policy di profiles.
--    Cari policy UPDATE. Jangan sampai user biasa bisa mengubah kolom role miliknya sendiri
--    (kalau ada policy "update own row" tanpa pembatasan kolom, staff bisa jadi admin).
select policyname, cmd, roles, qual, with_check
from pg_policies
where schemaname = 'public' and tablename = 'profiles';

-- B. Siapa yang boleh menjalankan function?
--    anon_boleh harus FALSE untuk copy_template_to_vehicle dan next_doc_number.
--    Kalau security_definer = true, kolom setelan harus memuat search_path.
select p.oid::regprocedure as function,
       p.prosecdef as security_definer,
       p.proconfig as setelan,
       has_function_privilege('anon', p.oid, 'execute') as anon_boleh,
       has_function_privilege('authenticated', p.oid, 'execute') as authenticated_boleh
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in ('app_role', 'copy_template_to_vehicle', 'next_doc_number', 'handle_new_user');

-- C. Kalau anon_boleh = true untuk dua RPC aplikasi, jalankan blok ini.
--    (Semua overload ikut dicabut, tanpa perlu menulis tipe argumen.)
do $$
declare f record;
begin
  for f in
    select p.oid::regprocedure as sig
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in ('copy_template_to_vehicle', 'next_doc_number')
  loop
    execute format('revoke execute on function %s from public, anon', f.sig);
  end loop;
end $$;