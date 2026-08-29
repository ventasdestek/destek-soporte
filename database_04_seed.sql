-- ============================================================
-- PARTE 3B: DATOS INICIALES (SEED)
-- Ejecuta DESPUÉS de database_03a_triggers.sql
-- ============================================================

-- Categorías por defecto
INSERT INTO public.categorias (nombre, descripcion, orden) VALUES
('Sistemas / Software', 'Software, licencias, sistemas operativos y aplicaciones', 1),
('Cámaras de seguridad (CCTV)', 'Cámaras IP, grabadores, accesorios de videovigilancia', 2),
('Accesorios / Hardware', 'Componentes, periféricos, cables y hardware diverso', 3),
('Redes y Conectividad', 'Routers, switches, puntos de acceso, cableado estructurado', 4),
('Servicios Profesionales', 'Instalación, configuración, mantenimiento y asesoría', 5)
ON CONFLICT (nombre) DO NOTHING;

-- Configuración inicial editable
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
('public_stat_clientes_value', '"500+"', 'Clientes satisfechos valor'),
('public_stat_clientes_label', '"Clientes satisfechos"', 'Clientes satisfechos etiqueta'),
('public_stat_experiencia_value', '"15+"', 'Años de experiencia valor'),
('public_stat_experiencia_label', '"Años de experiencia"', 'Años de experiencia etiqueta'),
('public_stat_resolucion_value', '"98%"', 'Tasa de resolución valor'),
('public_stat_resolucion_label', '"Tasa de resolución"', 'Tasa de resolución etiqueta'),
('public_stat_soporte_value', '"24/7"', 'Soporte disponible valor'),
('public_stat_soporte_label', '"Soporte disponible"', 'Soporte disponible etiqueta')
ON CONFLICT (clave) DO NOTHING;

-- Servicios de ejemplo
INSERT INTO public.servicios (titulo, descripcion, precio, duracion, modalidad, orden) VALUES
('Asesoría Tecnológica Online', 'Consultoría personalizada para definir la mejor estrategia tecnológica para tu negocio. Análisis de infraestructura, recomendaciones de software y hardware, planificación de migraciones.', 80.00, '60 minutos', 'online', 1),
('Soporte Técnico Remoto', 'Resolución de incidencias, configuración de equipos, instalación de software, optimización de sistemas y mantenimiento preventivo vía AnyDesk/TeamViewer.', 50.00, '45 minutos', 'online', 2),
('Desarrollo de Software a Medida', 'Desarrollo de aplicaciones web, móviles y de escritorio personalizadas. Metodología ágil, código limpio, testing automatizado y despliegue en la nube.', 1500.00, 'Según alcance', 'hibrido', 3),
('Instalación y Configuración CCTV', 'Instalación profesional de sistemas de videovigilancia: cámaras IP, grabadores NVR, configuración de acceso remoto y app móvil.', 300.00, '4-8 horas', 'presencial', 4),
('Mantenimiento Informático Mensual', 'Plan de mantenimiento proactivo: actualizaciones, backups, monitorizado, limpieza, optimización y soporte prioritario ilimitado.', 200.00, 'Mensual', 'hibrido', 5),
('Auditoría de Seguridad Informática', 'Análisis de vulnerabilidades, prueba de penetración, revisión de políticas de seguridad, cifrado de datos y cumplimiento RGPD.', 500.00, '2-3 días', 'hibrido', 6)
ON CONFLICT DO NOTHING;

-- Productos de ejemplo
INSERT INTO public.productos (nombre, descripcion, precio, stock, categoria_id, activo, orden) VALUES
('Kit 4 Cámaras CCTV IP 4K UltraHD', 'Visión nocturna a color 30m, grabación H.265+, certificación IP67 intemperie y app móvil sin costo.', 299.00, 12, (SELECT id FROM public.categorias WHERE nombre = 'Cámaras de seguridad (CCTV)' LIMIT 1), TRUE, 1),
('Licencia Software Antivirus Endpoint Pro 1 Año', 'Protección antimalware centralizada, anti-ransomware y firewall avanzado para PYMEs.', 39.99, 100, (SELECT id FROM public.categorias WHERE nombre = 'Sistemas / Software' LIMIT 1), TRUE, 2),
('Switch Gigabit Enterprise 16 Puertos Managed', 'Administración VLAN, QoS, eficiencia energética IEEE 802.3az y chasis metálico para rack.', 185.00, 8, (SELECT id FROM public.categorias WHERE nombre = 'Accesorios / Hardware' LIMIT 1), TRUE, 3)
ON CONFLICT DO NOTHING;