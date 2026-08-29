-- Ver columnas reales de servicios
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'servicios' 
ORDER BY ordinal_position;


-- Ver los servicios actuales
SELECT id, titulo, precio, modalidad, activo, created_at::date 
FROM public.servicios 
ORDER BY created_at DESC;

