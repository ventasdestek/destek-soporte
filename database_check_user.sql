-- Ver si el trigger existe
SELECT trigger_name, event_manipulation, action_timing
FROM information_schema.triggers
WHERE event_object_table = 'users'
  AND trigger_schema = 'auth';



-- Comparar usuarios en auth.users vs profiles
SELECT au.id, au.email, au.created_at::date AS auth_creado,
       p.id AS profile_id, p.role, p.created_at::date AS profile_creado
FROM auth.users au
LEFT JOIN public.profiles p ON p.id = au.id
ORDER BY au.created_at;
