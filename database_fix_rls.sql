-- ============================================================
-- FIX: Politicas RLS para que admins puedan hacer CRUD
-- Mantiene la seguridad: solo usuarios con role='admin'
-- en public.profiles pueden escribir
-- ============================================================

-- Funcion helper para verificar si el usuario es admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

-- ============================================================
-- SERVICIOS
-- ============================================================
DROP POLICY IF EXISTS "Admins gestionan servicios" ON public.servicios;
DROP POLICY IF EXISTS "Servicios activos visibles publicamente" ON public.servicios;
CREATE POLICY "Servicios activos visibles publicamente" ON public.servicios
  FOR SELECT USING (activo = TRUE);
CREATE POLICY "Admins gestionan servicios" ON public.servicios
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ============================================================
-- PRODUCTOS
-- ============================================================
DROP POLICY IF EXISTS "Admins gestionan productos" ON public.productos;
DROP POLICY IF EXISTS "Productos activos visibles publicamente" ON public.productos;
CREATE POLICY "Productos activos visibles publicamente" ON public.productos
  FOR SELECT USING (activo = TRUE);
CREATE POLICY "Admins gestionan productos" ON public.productos
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ============================================================
-- CATEGORIAS
-- ============================================================
DROP POLICY IF EXISTS "Admins gestionan categorias" ON public.categorias;
DROP POLICY IF EXISTS "Categorias activas visibles publicamente" ON public.categorias;
CREATE POLICY "Categorias activas visibles publicamente" ON public.categorias
  FOR SELECT USING (activo = TRUE);
CREATE POLICY "Admins gestionan categorias" ON public.categorias
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ============================================================
-- PEDIDOS
-- ============================================================
DROP POLICY IF EXISTS "Admins gestionan pedidos" ON public.pedidos;
DROP POLICY IF EXISTS "Usuarios ven sus propios pedidos" ON public.pedidos;
CREATE POLICY "Usuarios ven sus propios pedidos" ON public.pedidos
  FOR SELECT TO authenticated
  USING (cliente_id = auth.uid() OR public.is_admin());
CREATE POLICY "Admins gestionan pedidos" ON public.pedidos
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ============================================================
-- MENSAJES DE CONTACTO
-- ============================================================
DROP POLICY IF EXISTS "Admins gestionan mensajes" ON public.mensajes_contacto;
DROP POLICY IF EXISTS "Publico puede enviar mensajes" ON public.mensajes_contacto;
CREATE POLICY "Publico puede enviar mensajes" ON public.mensajes_contacto
  FOR INSERT TO anon, authenticated
  WITH CHECK (true);
CREATE POLICY "Admins gestionan mensajes" ON public.mensajes_contacto
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Refrescar cache
NOTIFY pgrst, 'reload schema';

-- Verificacion
SELECT tablename, policyname, cmd AS operacion
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('servicios', 'productos', 'categorias', 'pedidos', 'mensajes_contacto')
ORDER BY tablename, policyname;

