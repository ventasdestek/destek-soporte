-- ============================================================
-- SCRIPT SQL COMPLETO PARA SUPABASE (POSTGRESQL)
-- DESTEK SOPORTE - Base de datos completa
-- Ejecuta este script en el SQL Editor de Supabase
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

-- Índices para profiles
CREATE INDEX idx_profiles_email ON public.profiles(email);
CREATE INDEX idx_profiles_role ON public.profiles(role);

-- Trigger para updated_at
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

-- Índices
CREATE INDEX idx_categorias_activo ON public.categorias(activo);
CREATE INDEX idx_categorias_orden ON public.categorias(orden);

-- Trigger
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

-- Índices
CREATE INDEX idx_servicios_activo ON public.servicios(activo);
CREATE INDEX idx_servicios_orden ON public.servicios(orden);
CREATE INDEX idx_servicios_modalidad ON public.servicios(modalidad);

-- Trigger
CREATE TRIGGER trigger_servicios_updated_at
    BEFORE UPDATE ON public.servicios
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();