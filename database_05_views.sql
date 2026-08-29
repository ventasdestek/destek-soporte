-- ============================================================
-- PARTE 3C: VISTAS Y FUNCIONES AUXILIARES
-- Ejecuta DESPUÉS de database_04_seed.sql
-- ============================================================

-- ============================================================
-- VISTAS ÚTILES PARA EL DASHBOARD
-- ============================================================

-- Vista: Estadísticas del dashboard admin
CREATE OR REPLACE VIEW public.admin_stats AS
SELECT
    (SELECT COUNT(*) FROM public.profiles WHERE role = 'cliente') AS total_clientes,
    (SELECT COUNT(*) FROM public.servicios WHERE activo = TRUE) AS total_servicios,
    (SELECT COUNT(*) FROM public.productos WHERE activo = TRUE) AS total_productos,
    (SELECT COUNT(*) FROM public.pedidos WHERE estado = 'pendiente') AS pedidos_pendientes,
    (SELECT COUNT(*) FROM public.pedidos WHERE estado = 'completado') AS pedidos_completados,
    (SELECT COALESCE(SUM(total), 0) FROM public.pedidos WHERE estado = 'completado') AS ingreso_total,
    (SELECT COUNT(*) FROM public.mensajes_contacto WHERE leido = FALSE) AS mensajes_no_leidos;

-- Vista: Productos con categoría
CREATE OR REPLACE VIEW public.productos_con_categoria AS
SELECT
    p.*,
    c.nombre AS categoria_nombre,
    c.imagen_url AS categoria_imagen
FROM public.productos p
LEFT JOIN public.categorias c ON p.categoria_id = c.id
WHERE p.activo = TRUE;

-- Vista: Pedidos con info de cliente
CREATE OR REPLACE VIEW public.pedidos_con_cliente AS
SELECT
    pe.*,
    pr.nombre,
    pr.apellido,
    pr.email,
    pr.telefono
FROM public.pedidos pe
JOIN public.profiles pr ON pe.cliente_id = pr.id;

-- ============================================================
-- FUNCIONES AUXILIARES ADICIONALES
-- ============================================================

-- Función para obtener configuración pública (para usar en frontend)
CREATE OR REPLACE FUNCTION public.get_public_config()
RETURNS JSONB LANGUAGE plpgsql STABLE AS $$
DECLARE
    result JSONB := '{}';
BEGIN
    SELECT jsonb_object_agg(clave, valor)
    INTO result
    FROM public.configuracion
    WHERE clave LIKE 'public_%';
    
    RETURN COALESCE(result, '{}');
END;
$$;

-- ============================================================
-- STORAGE: Buckets para imágenes (Ejecutar en Dashboard > Storage)
-- ============================================================
-- Bucket para imágenes públicas (logos, banners, productos)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('public-images', 'public-images', TRUE);

-- Políticas de Storage (ejecutar en SQL Editor después de crear buckets):
-- CREATE POLICY "Imágenes públicas legibles" ON storage.objects
--     FOR SELECT USING (bucket_id = 'public-images');
-- CREATE POLICY "Admins suben imágenes" ON storage.objects
--     FOR INSERT WITH CHECK (
--         bucket_id = 'public-images' AND
--         EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
--     );
-- CREATE POLICY "Admins actualizan imágenes" ON storage.objects
--     FOR UPDATE USING (
--         bucket_id = 'public-images' AND
--         EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
--     );
-- CREATE POLICY "Admins borran imágenes" ON storage.objects
--     FOR DELETE USING (
--         bucket_id = 'public-images' AND
--         EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
--     );

-- ============================================================
-- INSTRUCCIONES POST-INSTALACIÓN
-- ============================================================
-- 1. Ejecuta database_01_schema.sql, luego database_02_rls.sql, luego database_03a_triggers.sql, database_04_seed.sql, luego este archivo
-- 2. Ve a Authentication > Settings y configura:
--    - Site URL: https://tu-dominio.vercel.app
--    - Redirect URLs: https://tu-dominio.vercel.app/auth/callback
-- 3. Ve a Storage y crea bucket 'public-images' como público
-- 4. Aplica las políticas de Storage (comentadas arriba)
-- 5. Crea tu usuario admin registrándote con el email de 'private_admin_email'
-- 6. En Supabase > Authentication > Users, edita el usuario y pon role='admin' en raw_user_meta_data
--    O ejecuta: UPDATE public.profiles SET role='admin' WHERE email='admin@desteksoporte.com';