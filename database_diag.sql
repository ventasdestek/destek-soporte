-- DIAGNOSTICO RAPIDO: ejecuta este script en Supabase SQL Editor
-- y pegame los resultados

-- 1) FKs de pedidos (es la que nos importa)
SELECT 'FKs de pedidos:' AS seccion, tc.constraint_name,
       kcu.column_name || ' -> ' || ccu.table_name || '.' || ccu.column_name AS relacion
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public' AND tc.table_name = 'pedidos';



-- 2) Definicion de la vista pedidos_con_cliente
SELECT 'Vista pedidos_con_cliente:' AS seccion, view_definition
FROM information_schema.views
WHERE table_schema = 'public' AND table_name = 'pedidos_con_cliente';


-- 3) Politicas RLS de las 5 tablas principales
SELECT tablename, policyname, cmd AS operacion
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('productos', 'servicios', 'categorias', 'pedidos', 'mensajes_contacto')
ORDER BY tablename, policyname;


-- 4) Tu usuario y rol
SELECT 'Tu perfil:' AS seccion, id, email, role, created_at::date
FROM public.profiles
ORDER BY created_at;


-- 5) Conteos de datos
SELECT 'Conteos:' AS seccion, 'productos' AS tabla, COUNT(*)::text AS total FROM public.productos
UNION ALL SELECT '', 'servicios', COUNT(*)::text FROM public.servicios
UNION ALL SELECT '', 'categorias', COUNT(*)::text FROM public.categorias
UNION ALL SELECT '', 'pedidos', COUNT(*)::text FROM public.pedidos
UNION ALL SELECT '', 'mensajes', COUNT(*)::text FROM public.mensajes_contacto
UNION ALL SELECT '', 'usuarios', COUNT(*)::text FROM public.profiles;


-- 6) Confirmar que la vista admin_stats devuelve datos
SELECT 'admin_stats:' AS seccion, * FROM public.admin_stats;
