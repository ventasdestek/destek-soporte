-- ============================================================
-- FIX: FK entre pedidos.cliente_id y auth.users.id
-- Soluciona el error: "Could not find a relationship between
-- pedidos and cliente_id in the schema cache"
-- ============================================================

-- 1) Diagnostico: ver TODAS las FKs de pedidos (por si existe con otro nombre)
SELECT 'FKs actuales:' AS info, tc.constraint_name,
       kcu.column_name || ' -> ' || ccu.table_name || '.' || ccu.column_name AS relacion
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
  AND tc.table_name = 'pedidos';

-- 2) Eliminar la FK con nombre conocido (puede existir con este nombre)
ALTER TABLE public.pedidos DROP CONSTRAINT IF EXISTS pedidos_cliente_id_fkey;

-- 3) Verificar si existe OTRA FK en cliente_id
DO $$
DECLARE
  v_constraint_name TEXT;
BEGIN
  SELECT tc.constraint_name INTO v_constraint_name
  FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
  WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
    AND tc.table_name = 'pedidos'
    AND kcu.column_name = 'cliente_id'
  LIMIT 1;

  IF v_constraint_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.pedidos DROP CONSTRAINT %I', v_constraint_name);
    RAISE NOTICE 'Eliminada FK previa: %', v_constraint_name;
  ELSE
    RAISE NOTICE 'No hay FK previa en cliente_id';
  END IF;
END $$;




-- 4) Crear la FK limpia con el nombre correcto
ALTER TABLE public.pedidos
  ADD CONSTRAINT pedidos_cliente_id_fkey
  FOREIGN KEY (cliente_id)
  REFERENCES auth.users(id)
  ON DELETE CASCADE;

-- 5) Refrescar el schema cache de PostgREST (importante)
NOTIFY pgrst, 'reload schema';

-- 6) Verificar politica RLS admin
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'pedidos'
      AND policyname = 'Admins gestionan todos los pedidos'
  ) THEN
    EXECUTE 'CREATE POLICY "Admins gestionan todos los pedidos" ON public.pedidos
      FOR ALL USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = ''admin'')
      )';
    RAISE NOTICE 'Politica RLS creada';
  ELSE
    RAISE NOTICE 'Politica RLS ya existe';
  END IF;
END $$;

-- 7) Verificacion final
SELECT 'FK final' AS tipo, tc.constraint_name,
       kcu.column_name || ' -> ' || ccu.table_name || '.' || ccu.column_name AS relacion
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public' AND tc.table_name = 'pedidos'
UNION ALL
SELECT 'Policy', policyname, cmd::text
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'pedidos';

