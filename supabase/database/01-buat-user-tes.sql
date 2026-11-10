-- Buat 3 user dulu lewat Dashboard:
--   Authentication > Users > Add user > Create new user
--   (centang "Auto Confirm User")
--   admin@test.com, staff@test.com, owner@test.com
--   Password bebas (samakan dengan blok $akun di 03-tes-rls.ps1)
-- Kalau domain test.com ditolak, pakai @example.com dan ganti juga di skrip tes.
--
-- Trigger handle_new_user otomatis membuat baris profiles (default staff).
-- Jalankan ini di SQL Editor setelah ketiganya ada:

update public.profiles set role = 'admin'
where id = (select id from auth.users where email = 'admin@test.com');

update public.profiles set role = 'owner'
where id = (select id from auth.users where email = 'owner@test.com');

update public.profiles set role = 'staff', is_lead = false
where id = (select id from auth.users where email = 'staff@test.com');

-- Cek hasil: harus muncul 3 baris dengan role berbeda
select u.email, p.role, p.is_lead
from auth.users u
join public.profiles p on p.id = u.id
where u.email in ('admin@test.com', 'staff@test.com', 'owner@test.com');