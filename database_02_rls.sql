-- ============================================================
-- PARTE 2: POLÍTICAS RLS (ROW LEVEL SECURITY)
-- Ejecuta DESPUÉS de database_01_schema.sql
-- ============================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categorias ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.servicios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.productos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mensajes_contacto ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.configuracion ENABLE ROW LEVEL SECURITY;

-- Función auxiliar SECURITY DEFINER que evita la recursión
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin'
    );
END;
$$;

-- ============================================================
-- POLÍTICAS PARA: profiles
-- ============================================================
-- Usuarios ven su propio perfil
CREATE POLICY "Usuarios ven su perfil" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

-- Usuarios actualizan su propio perfil
CREATE POLICY "Usuarios actualizan su perfil" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Admins ven todos los perfiles
CREATE POLICY "Admins ven todos los perfiles" ON public.profiles
    FOR SELECT USING (public.is_admin());

-- Admins actualizan cualquier perfil
CREATE POLICY "Admins actualizan cualquier perfil" ON public.profiles
    FOR UPDATE USING (public.is_admin());

-- ============================================================
-- POLÍTICAS PARA: categorias (Público read, Admin write)
-- ============================================================
CREATE POLICY "Categorías activas visibles para todos" ON public.categorias
    FOR SELECT USING (activo = TRUE);

CREATE POLICY "Admins gestionan categorías" ON public.categorias
    FOR ALL USING (public.is_admin());

-- ============================================================
-- POLÍTICAS PARA: servicios (Público read, Admin write)
-- ============================================================
CREATE POLICY "Servicios activos visibles para todos" ON public.servicios
    FOR SELECT USING (activo = TRUE);

CREATE POLICY "Admins gestionan servicios" ON public.servicios
    FOR ALL USING (public.is_admin());

-- ============================================================
-- POLÍTICAS PARA: productos (Público read, Admin write)
-- ============================================================
CREATE POLICY "Productos activos visibles para todos" ON public.productos
    FOR SELECT USING (activo = TRUE);

CREATE POLICY "Admins gestionan productos" ON public.productos
    FOR ALL USING (public.is_admin());

-- ============================================================
-- POLÍTICAS PARA: pedidos
-- ============================================================
-- Clientes ven sus propios pedidos
CREATE POLICY "Clientes ven sus pedidos" ON public.pedidos
    FOR SELECT USING (auth.uid() = cliente_id);

-- Clientes crean pedidos
CREATE POLICY "Clientes crean pedidos" ON public.pedidos
    FOR INSERT WITH CHECK (auth.uid() = cliente_id);

-- Admins ven y gestionan todos los pedidos
CREATE POLICY "Admins gestionan todos los pedidos" ON public.pedidos
    FOR ALL USING (public.is_admin());

-- ============================================================
-- POLÍTICAS PARA: mensajes_contacto
-- ============================================================
-- Cualquiera puede insertar (formulario público)
CREATE POLICY "Público inserta mensajes" ON public.mensajes_contacto
    FOR INSERT WITH CHECK (TRUE);

-- Solo admins leen mensajes
CREATE POLICY "Admins leen mensajes" ON public.mensajes_contacto
    FOR SELECT USING (public.is_admin());

-- Admins actualizan (marcar como leído)
CREATE POLICY "Admins actualizan mensajes" ON public.mensajes_contacto
    FOR UPDATE USING (public.is_admin());

-- ============================================================
-- POLÍTICAS PARA: configuracion
-- ============================================================
-- Público lee configuraciones públicas (claves que empiezan con 'public_')
CREATE POLICY "Público lee config pública" ON public.configuracion
    FOR SELECT USING (clave LIKE 'public_%');

-- Admins gestionan toda la configuración
CREATE POLICY "Admins gestionan configuración" ON public.configuracion
    FOR ALL USING (public.is_admin());