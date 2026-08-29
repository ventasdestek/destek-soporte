-- ============================================================
-- SCRIPT SQL COMPLETO Y CONSOLIDADO - DESTEK SOPORTE
-- Ejecuta este ÚNICO archivo completo en el SQL Editor de Supabase
-- (Sustituye a database_01...05, que tenían tablas faltantes)
-- ============================================================

-- Habilitar extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- FUNCIÓN AUXILIAR: handle_updated_at()
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- ============================================================
-- TABLA: profiles (Extensión de auth.users)
-- ============================================================
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'cliente' CHECK (role IN ('admin', 'cliente')),
    nombre TEXT,
    apellido TEXT,
    telefono TEXT,
    direccion TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_profiles_email ON public.profiles(email);
CREATE INDEX idx_profiles_role ON public.profiles(role);

CREATE TRIGGER trigger_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- TABLA: categorias
-- ============================================================
CREATE TABLE public.categorias (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre TEXT NOT NULL UNIQUE,
    descripcion TEXT,
    imagen_url TEXT,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    orden INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_categorias_activo ON public.categorias(activo);
CREATE INDEX idx_categorias_orden ON public.categorias(orden);

CREATE TRIGGER trigger_categorias_updated_at
    BEFORE UPDATE ON public.categorias
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- TABLA: servicios
-- ============================================================
CREATE TABLE public.servicios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    titulo TEXT NOT NULL,
    descripcion TEXT NOT NULL,
    precio DECIMAL(10, 2) NOT NULL DEFAULT 0,
    duracion TEXT,
    modalidad TEXT NOT NULL DEFAULT 'online' CHECK (modalidad IN ('online', 'presencial', 'hibrido')),
    imagen_url TEXT,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    orden INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_servicios_activo ON public.servicios(activo);
CREATE INDEX idx_servicios_orden ON public.servicios(orden);
CREATE INDEX idx_servicios_modalidad ON public.servicios(modalidad);

CREATE TRIGGER trigger_servicios_updated_at
    BEFORE UPDATE ON public.servicios
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- TABLA: productos
-- ============================================================
CREATE TABLE public.productos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre TEXT NOT NULL,
    descripcion TEXT,
    precio DECIMAL(10, 2) NOT NULL DEFAULT 0,
    stock INTEGER NOT NULL DEFAULT 0,
    categoria_id UUID REFERENCES public.categorias(id) ON DELETE SET NULL,
    imagen_url TEXT,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    orden INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_productos_activo ON public.productos(activo);
CREATE INDEX idx_productos_categoria ON public.productos(categoria_id);
CREATE INDEX idx_productos_orden ON public.productos(orden);

CREATE TRIGGER trigger_productos_updated_at
    BEFORE UPDATE ON public.productos
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- TABLA: pedidos
-- ============================================================
CREATE TABLE public.pedidos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cliente_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    tipo TEXT NOT NULL DEFAULT 'producto' CHECK (tipo IN ('producto', 'servicio')),
    referencia_id UUID,
    item TEXT NOT NULL,
    total DECIMAL(10, 2) NOT NULL DEFAULT 0,
    estado TEXT NOT NULL DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'procesando', 'completado', 'cancelado')),
    notas TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_pedidos_cliente ON public.pedidos(cliente_id);
CREATE INDEX idx_pedidos_estado ON public.pedidos(estado);

CREATE TRIGGER trigger_pedidos_updated_at
    BEFORE UPDATE ON public.pedidos
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- TABLA: mensajes_contacto
-- ============================================================
CREATE TABLE public.mensajes_contacto (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre TEXT NOT NULL,
    email TEXT NOT NULL,
    telefono TEXT,
    empresa TEXT,
    tipo_consulta TEXT,
    mensaje TEXT NOT NULL,
    leido BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_mensajes_leido ON public.mensajes_contacto(leido);

-- ============================================================
-- TABLA: configuracion
-- ============================================================
CREATE TABLE public.configuracion (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    clave TEXT NOT NULL UNIQUE,
    valor JSONB NOT NULL DEFAULT '{}',
    descripcion TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trigger_configuracion_updated_at
    BEFORE UPDATE ON public.configuracion
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- POLÍTICAS RLS Y FUNCIONES AUXILIARES
-- ============================================================
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

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categorias ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.servicios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.productos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mensajes_contacto ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.configuracion ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios ven su perfil" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Usuarios actualizan su perfil" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admins ven todos los perfiles" ON public.profiles
    FOR SELECT USING (public.is_admin());

CREATE POLICY "Admins actualizan cualquier perfil" ON public.profiles
    FOR UPDATE USING (public.is_admin());

CREATE POLICY "Categorías activas visibles para todos" ON public.categorias
    FOR SELECT USING (activo = TRUE);

CREATE POLICY "Admins gestionan categorías" ON public.categorias
    FOR ALL USING (public.is_admin());

CREATE POLICY "Servicios activos visibles para todos" ON public.servicios
    FOR SELECT USING (activo = TRUE);

CREATE POLICY "Admins gestionan servicios" ON public.servicios
    FOR ALL USING (public.is_admin());

CREATE POLICY "Productos activos visibles para todos" ON public.productos
    FOR SELECT USING (activo = TRUE);

CREATE POLICY "Admins gestionan productos" ON public.productos
    FOR ALL USING (public.is_admin());

CREATE POLICY "Clientes ven sus pedidos" ON public.pedidos
    FOR SELECT USING (auth.uid() = cliente_id);

CREATE POLICY "Clientes crean pedidos" ON public.pedidos
    FOR INSERT WITH CHECK (auth.uid() = cliente_id);

CREATE POLICY "Admins gestionan todos los pedidos" ON public.pedidos
    FOR ALL USING (public.is_admin());

CREATE POLICY "Público inserta mensajes" ON public.mensajes_contacto
    FOR INSERT WITH CHECK (TRUE);

CREATE POLICY "Admins leen mensajes" ON public.mensajes_contacto
    FOR SELECT USING (public.is_admin());

CREATE POLICY "Admins actualizan mensajes" ON public.mensajes_contacto
    FOR UPDATE USING (public.is_admin());

CREATE POLICY "Público lee config pública" ON public.configuracion
    FOR SELECT USING (clave LIKE 'public_%');

CREATE POLICY "Admins gestionan configuración" ON public.configuracion
    FOR ALL USING (public.is_admin());

-- ============================================================
-- TRIGGERS Y FUNCIONES: crear perfil automáticamente al registrar usuario
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, role, nombre, apellido)
    VALUES (
        NEW.id,
        NEW.email,
        CASE
            WHEN NEW.email = 'admin@desteksoporte.com' THEN 'admin'
            ELSE 'cliente'
        END,
        NEW.raw_user_meta_data->>'nombre',
        NEW.raw_user_meta_data->>'apellido'
    );
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- DATOS INICIALES (SEED)
-- ============================================================
INSERT INTO public.categorias (nombre, descripcion, orden) VALUES
('Sistemas / Software', 'Software, licencias, sistemas operativos y aplicaciones', 1),
('Cámaras de seguridad (CCTV)', 'Cámaras IP, grabadores, accesorios de videovigilancia', 2),
('Accesorios / Hardware', 'Componentes, periféricos, cables y hardware diverso', 3),
('Redes y Conectividad', 'Routers, switches, puntos de acceso, cableado estructurado', 4),
('Servicios Profesionales', 'Instalación, configuración, mantenimiento y asesoría', 5)
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO public.configuracion (clave, valor, descripcion) VALUES
('public_hero_title', '"Soluciones Tecnológicas a tu Medida"', 'Título principal del hero'),
('public_hero_subtitle', '"Asesoría, soporte remoto, desarrollo de software y venta de hardware. Tu partner tecnológico de confianza."', 'Subtítulo del hero'),
('public_hero_cta_text', '"Solicitar Asesoría Gratuita"', 'Texto del botón CTA principal'),
('public_hero_cta_link', '"/contacto"', 'Enlace del botón CTA principal'),
('public_company_logo_url', '""', 'URL del logo (Storage)'),
('public_company_name', '"Destek Soporte"', 'Nombre de la empresa'),
('public_company_tagline', '"Tecnología que impulsa tu negocio"', 'Eslogan de la empresa'),
('public_contact_email', '"contacto@desteksoporte.com"', 'Email de contacto'),
('public_contact_phone', '"+34 600 000 000"', 'Teléfono de contacto'),
('public_contact_whatsapp', '"34600000000"', 'WhatsApp (solo números)'),
('public_contact_address', '"Calle Ejemplo 123, 28001 Madrid, España"', 'Dirección física'),
('public_social_facebook', '"https://facebook.com"', 'Facebook URL'),
('public_social_twitter', '"https://twitter.com"', 'Twitter/X URL'),
('public_social_linkedin', '"https://linkedin.com"', 'LinkedIn URL'),
('public_social_instagram', '"https://instagram.com"', 'Instagram URL'),
('public_social_youtube', '"https://youtube.com"', 'YouTube URL'),
('public_whatsapp_message', '"Hola, me gustaría más información sobre sus servicios."', 'Mensaje predeterminado WhatsApp'),
('public_seo_title', '"Destek Soporte | Servicios Tecnológicos, Soporte y Desarrollo"', 'SEO Title'),
('public_seo_description', '"Empresa de servicios tecnológicos: asesoría, soporte remoto, desarrollo de software a medida y venta de hardware. ¡Contáctanos!"', 'SEO Description'),
('private_admin_email', '"admin@desteksoporte.com"', 'Email del administrador principal (para notificaciones)'),
('public_stat_clientes_value', '"500+"', 'Clientes satisfied valor'),
('public_stat_clientes_label', '"Clientes satisfechos"', 'Clientes satisfied etiqueta'),
('public_stat_experiencia_value', '"15+"', 'Años de experiencia valor'),
('public_stat_experiencia_label', '"Años de experiencia"', 'Años de experiencia etiqueta'),
('public_stat_resolucion_value', '"98%"', 'Tasa de resolución valor'),
('public_stat_resolucion_label', '"Tasa de resolución"', 'Tasa de resolución etiqueta'),
('public_stat_soporte_value', '"24/7"', 'Soporte disponible valor'),
('public_stat_soporte_label', '"Soporte disponible"', 'Soporte disponible etiqueta')
ON CONFLICT (clave) DO NOTHING;

INSERT INTO public.servicios (titulo, descripcion, precio, duracion, modalidad, orden) VALUES
('Asesoría Tecnológica Online', 'Consultoría personalizada para definir la mejor estrategia tecnológica para tu negocio. Análisis de infraestructura, recomendaciones de software y hardware, planificación de migraciones.', 80.00, '60 minutos', 'online', 1),
('Soporte Técnico Remoto', 'Resolución de incidencias, configuración de equipos, instalación de software, optimización de sistemas y mantenimiento preventivo vía AnyDesk/TeamViewer.', 50.00, '45 minutos', 'online', 2),
('Desarrollo de Software a Medida', 'Desarrollo de aplicaciones web, móviles y de escritorio personalizadas. Metodología ágil, código limpio, testing automatizado y despliegue en la nube.', 1500.00, 'Según alcance', 'hibrido', 3),
('Instalación y Configuración CCTV', 'Instalación profesional de sistemas de videovigilancia: cámaras IP, grabadores NVR, configuración de acceso remoto y app móvil.', 300.00, '4-8 horas', 'presencial', 4),
('Mantenimiento Informático Mensual', 'Plan de mantenimiento proactivo: actualizaciones, backups, monitorizado, limpieza, optimización y soporte prioritario ilimitado.', 200.00, 'Mensual', 'hibrido', 5),
('Auditoría de Seguridad Informática', 'Análisis de vulnerabilidades, prueba de penetración, revisión de políticas de seguridad, cifrado de datos y cumplimiento RGPD.', 500.00, '2-3 días', 'hibrido', 6)
ON CONFLICT DO NOTHING;

-- ============================================================
-- VISTAS ÚTILES PARA EL DASHBOARD
-- ============================================================
CREATE OR REPLACE VIEW public.admin_stats AS
SELECT
    (SELECT COUNT(*) FROM public.profiles WHERE role = 'cliente') AS total_clientes,
    (SELECT COUNT(*) FROM public.servicios WHERE activo = TRUE) AS total_servicios,
    (SELECT COUNT(*) FROM public.productos WHERE activo = TRUE) AS total_productos,
    (SELECT COUNT(*) FROM public.pedidos WHERE estado = 'pendiente') AS pedidos_pendientes,
    (SELECT COUNT(*) FROM public.pedidos WHERE estado = 'completado') AS pedidos_completados,
    (SELECT COALESCE(SUM(total), 0) FROM public.pedidos WHERE estado = 'completado') AS ingreso_total,
    (SELECT COUNT(*) FROM public.mensajes_contacto WHERE leido = FALSE) AS mensajes_no_leidos;

CREATE OR REPLACE VIEW public.productos_con_categoria AS
SELECT
    p.*,
    c.nombre AS categoria_nombre,
    c.imagen_url AS categoria_imagen
FROM public.productos p
LEFT JOIN public.categorias c ON p.categoria_id = c.id
WHERE p.activo = TRUE;

CREATE OR REPLACE VIEW public.pedidos_con_cliente AS
SELECT
    pe.*,
    pr.nombre,
    pr.apellido,
    pr.email,
    pr.telefono
FROM public.pedidos pe
JOIN public.profiles pr ON pe.cliente_id = pr.id;

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
-- FIN DEL SCRIPT. INSTRUCCIONES POST-INSTALACIÓN:
-- 1. Ve a Authentication > URL Configuration y configura:
--    - Site URL: https://tu-dominio.vercel.app
--    - Redirect URLs: https://tu-dominio.vercel.app/**
-- 2. Ve a Storage y crea bucket 'public-images' como público (opcional)
-- 3. Regístrate en /registro con el email admin@desteksoporte.com
--    para que el trigger le asigne automáticamente role='admin'
-- ============================================================
