-- ==========================================================
--        CONTROL DE ACCESO - POSTGRESQL VERSION
-- ==========================================================

-- Crear esquema (opcional)
CREATE SCHEMA IF NOT EXISTS control_acceso;
SET search_path TO control_acceso;

-- ==========================================================
-- TABLAS
-- ==========================================================

CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS permisos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    modulo VARCHAR(50) NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS rol_permisos (
    id SERIAL PRIMARY KEY,
    rol_id INT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permiso_id INT NOT NULL REFERENCES permisos(id) ON DELETE CASCADE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_rol_permiso UNIQUE (rol_id, permiso_id)
);

CREATE TABLE IF NOT EXISTS usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(100) NOT NULL UNIQUE,
    contrasena TEXT NOT NULL,
    rol_id INT NOT NULL REFERENCES roles(id),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(30) NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo', 'inactivo'))
);

CREATE TABLE IF NOT EXISTS visitantes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    identificacion VARCHAR(50) NOT NULL UNIQUE,
    empresa VARCHAR(100),
    motivo TEXT,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(30) NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo', 'inactivo'))
);

CREATE TABLE IF NOT EXISTS credenciales (
    id SERIAL PRIMARY KEY,
    visitante_id INT NOT NULL REFERENCES visitantes(id),
    codigo VARCHAR(50) NOT NULL UNIQUE,
    estado VARCHAR(30) DEFAULT 'activa' CHECK (estado IN ('activa', 'inactiva')),
    fecha_emision TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion TIMESTAMP,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS accesos (
    id SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuarios(id),
    visitante_id INT REFERENCES visitantes(id),
    tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('entrada', 'salida')),
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    autorizado BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS alertas (
    id SERIAL PRIMARY KEY,
    descripcion VARCHAR(255) NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    nivel VARCHAR(30) DEFAULT 'medio' CHECK (nivel IN ('bajo', 'medio', 'alto')),
    usuario_id INT REFERENCES usuarios(id),
    visitante_id INT REFERENCES visitantes(id),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================================
-- INSERTS BASE
-- ==========================================================

INSERT INTO roles (id, nombre, descripcion) VALUES
(1, 'administrador', 'Administrador completo del sistema con todos los permisos'),
(2, 'guardia', 'Personal de seguridad que gestiona accesos y visitantes'),
(3, 'recepcion', 'Personal de recepción con permisos limitados'),
(4, 'supervisor', 'Supervisor con permisos de visualización y reportes')
ON CONFLICT DO NOTHING;

INSERT INTO permisos (nombre, descripcion, modulo) VALUES
('ver_dashboard', 'Permite ver el dashboard principal', 'dashboard'),
('ver_visitantes', 'Permite ver la lista de visitantes', 'visitantes'),
('crear_visitantes', 'Permite crear nuevos visitantes', 'visitantes'),
('editar_visitantes', 'Permite editar visitantes existentes', 'visitantes'),
('eliminar_visitantes', 'Permite eliminar visitantes', 'visitantes'),
('cambiar_estado_visitantes', 'Permite activar/desactivar visitantes', 'visitantes'),
('generar_credenciales', 'Permite generar credenciales para visitantes', 'visitantes'),
('control_acceso', 'Permite registrar entradas y salidas', 'acceso'),
('ver_registro_accesos', 'Permite ver el historial de accesos', 'acceso'),
('ver_usuarios', 'Permite ver la lista de usuarios', 'usuarios'),
('crear_usuarios', 'Permite crear nuevos usuarios', 'usuarios'),
('editar_usuarios', 'Permite editar usuarios existentes', 'usuarios'),
('eliminar_usuarios', 'Permite eliminar usuarios', 'usuarios'),
('cambiar_estado_usuarios', 'Permite activar/desactivar usuarios', 'usuarios'),
('asignar_roles', 'Permite asignar roles a usuarios', 'usuarios'),
('ver_alertas', 'Permite ver las alertas del sistema', 'alertas'),
('crear_alertas', 'Permite crear nuevas alertas', 'alertas'),
('editar_alertas', 'Permite editar alertas existentes', 'alertas'),
('eliminar_alertas', 'Permite eliminar alertas', 'alertas'),
('ver_reportes', 'Permite ver reportes', 'reportes'),
('generar_reportes', 'Permite generar nuevos reportes', 'reportes'),
('exportar_reportes', 'Permite exportar reportes a PDF/CSV', 'reportes'),
('gestionar_roles', 'Permite gestionar roles del sistema', 'configuracion'),
('gestionar_permisos', 'Permite gestionar permisos del sistema', 'configuracion'),
('configurar_sistema', 'Permite configurar parámetros del sistema', 'configuracion')
ON CONFLICT DO NOTHING;

-- DAR TODOS LOS PERMISOS AL ADMINISTRADOR
INSERT INTO rol_permisos (rol_id, permiso_id)
SELECT 1, id FROM permisos
ON CONFLICT DO NOTHING;

-- ROL GUARDIA
INSERT INTO rol_permisos (rol_id, permiso_id)
SELECT 2, id FROM permisos
WHERE nombre IN (
    'ver_dashboard',
    'ver_visitantes',
    'crear_visitantes',
    'editar_visitantes',
    'cambiar_estado_visitantes',
    'generar_credenciales',
    'control_acceso',
    'ver_registro_accesos',
    'ver_alertas',
    'crear_alertas'
)
ON CONFLICT DO NOTHING;

-- ROL RECEPCIÓN
INSERT INTO rol_permisos (rol_id, permiso_id)
SELECT 3, id FROM permisos
WHERE nombre IN (
    'ver_dashboard',
    'ver_visitantes',
    'crear_visitantes',
    'editar_visitantes',
    'generar_credenciales',
    'control_acceso',
    'ver_alertas',
    'crear_alertas'
)
ON CONFLICT DO NOTHING;

-- ROL SUPERVISOR
INSERT INTO rol_permisos (rol_id, permiso_id)
SELECT 4, id FROM permisos
WHERE nombre IN (
    'ver_dashboard',
    'ver_visitantes',
    'ver_registro_accesos',
    'ver_usuarios',
    'ver_alertas',
    'ver_reportes',
    'generar_reportes',
    'exportar_reportes'
)
ON CONFLICT DO NOTHING;

-- USUARIOS BASE (password: hash SHA256)
INSERT INTO usuarios (nombre, correo, contrasena, rol_id, estado) VALUES
('Administrador Principal', 'admin@controlacceso.com', encode(digest('admin123', 'sha256'), 'hex'), 1, 'activo'),
('Guardia de Seguridad', 'guardia@controlacceso.com', encode(digest('guardia123', 'sha256'), 'hex'), 2, 'activo'),
('Recepcionista', 'recepcion@controlacceso.com', encode(digest('recepcion123', 'sha256'), 'hex'), 3, 'activo'),
('Supervisor', 'supervisor@controlacceso.com', encode(digest('supervisor123', 'sha256'), 'hex'), 4, 'activo')
ON CONFLICT DO NOTHING;

-- VISITANTES EJEMPLO
INSERT INTO visitantes (nombre, identificacion, empresa, motivo, estado) VALUES
('Juan Pérez', 'V-12345678', 'Empresa ABC', 'Reunión de negocios', 'activo'),
('María García', 'V-87654321', 'Compañía XYZ', 'Entrega de documentos', 'activo'),
('Carlos López', 'V-11223344', 'Corporación DEF', 'Visita técnica', 'activo'),
('Ana Martínez', 'V-44332211', 'Industrias GHI', 'Entrevista de trabajo', 'activo')
ON CONFLICT DO NOTHING;

-- CREDENCIALES (UUID auto-generado)
INSERT INTO credenciales (visitante_id, codigo, estado, fecha_expiracion)
SELECT id, SUBSTRING(md5(random()::text), 1, 8), 'activa', NOW() + INTERVAL '8 hours'
FROM visitantes;

-- ACCESOS EJEMPLO
INSERT INTO accesos (usuario_id, visitante_id, tipo, autorizado) VALUES
(2, 1, 'entrada', TRUE),
(2, 2, 'entrada', TRUE),
(2, 1, 'salida', TRUE),
(2, 3, 'entrada', TRUE);

-- ALERTAS EJEMPLO
INSERT INTO alertas (descripcion, nivel, usuario_id) VALUES
('Intento de acceso fuera del horario permitido', 'medio', 2),
('Visitante con credencial expirada intentó ingresar', 'alto', 2),
('Acceso denegado por identificación no válida', 'alto', 2);

-- ==========================================================
-- ÍNDICES
-- ==========================================================

CREATE INDEX IF NOT EXISTS idx_usuarios_estado ON usuarios(estado);
CREATE INDEX IF NOT EXISTS idx_usuarios_rol ON usuarios(rol_id);
CREATE INDEX IF NOT EXISTS idx_visitantes_estado ON visitantes(estado);
CREATE INDEX IF NOT EXISTS idx_visitantes_identificacion ON visitantes(identificacion);
CREATE INDEX IF NOT EXISTS idx_credenciales_estado ON credenciales(estado);
CREATE INDEX IF NOT EXISTS idx_credenciales_codigo ON credenciales(codigo);
CREATE INDEX IF NOT EXISTS idx_credenciales_expiracion ON credenciales(fecha_expiracion);
CREATE INDEX IF NOT EXISTS idx_accesos_fecha ON accesos(fecha_hora);
CREATE INDEX IF NOT EXISTS idx_accesos_visitante ON accesos(visitante_id);
CREATE INDEX IF NOT EXISTS idx_alertas_fecha ON alertas(fecha);
CREATE INDEX IF NOT EXISTS idx_alertas_nivel ON alertas(nivel);
CREATE INDEX IF NOT EXISTS idx_rol_permisos_rol ON rol_permisos(rol_id);
CREATE INDEX IF NOT EXISTS idx_rol_permisos_permiso ON rol_permisos(permiso_id);
