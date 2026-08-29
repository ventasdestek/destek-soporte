-- ============================================================
-- PARTE 3A: TRIGGERS Y FUNCIONES
-- Ejecuta DESPUÉS de database_02_rls.sql
-- ============================================================

-- ============================================================
-- FUNCIÓN Y TRIGGER: Crear perfil al registrar usuario
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

-- Trigger en auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();