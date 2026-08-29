-- ============================================================
-- RESET DE ESTADISTICAS - DESTEK SOPORTE
-- Borra SOLO los datos transaccionales / de prueba:
--   * pedidos (y sus items si existen)
--   * mensajes_contacto
-- MANTIENE intactos:
--   * categorias, productos, servicios (catalogo)
--   * configuracion (textos del sitio)
--   * profiles (cuentas de usuarios)
-- ============================================================

-- 0) Backup por si necesitas revertir
CREATE TABLE IF NOT EXISTS public._backup_pedidos AS
  SELECT * FROM public.pedidos;
CREATE TABLE IF NOT EXISTS public._backup_mensajes AS
  SELECT * FROM public.mensajes_contacto;

-- 1) Borrar pedidos (CASCADE limpia dependencias)
TRUNCATE TABLE public.pedidos RESTART IDENTITY CASCADE;

-- 2) Borrar mensajes de contacto
TRUNCATE TABLE public.mensajes_contacto RESTART IDENTITY CASCADE;


-- 3) Verificar conteos tras el reset
SELECT 'pedidos' AS tabla, COUNT(*) AS total FROM public.pedidos
UNION ALL
SELECT 'mensajes_contacto', COUNT(*) FROM public.mensajes_contacto
UNION ALL
SELECT 'productos (intacto)', COUNT(*) FROM public.productos
UNION ALL
SELECT 'servicios (intacto)', COUNT(*) FROM public.servicios
UNION ALL
SELECT 'categorias (intacto)', COUNT(*) FROM public.categorias
UNION ALL
SELECT 'configuracion (intacto)', COUNT(*) FROM public.configuracion;

-- 4) Mensaje final
DO $$
BEGIN
  RAISE NOTICE 'Reset completado. El panel admin mostrara 0 ventas / 0 pedidos pendientes.';
  RAISE NOTICE 'Backups guardados en: public._backup_pedidos y public._backup_mensajes';
END $$;

