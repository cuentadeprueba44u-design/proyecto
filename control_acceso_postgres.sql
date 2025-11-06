-- ==========================================================
--        CONTROL DE ACCESO - POSTGRESQL VERSION CORREGIDA
-- ==========================================================

-- Crear esquema
CREATE SCHEMA IF NOT EXISTS control_acceso;
SET search_path TO control_acceso;

-- ==========================================================
-- TABLAS PRINCIPALES
-- ==========================================================

-- Tabla de roles
CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de permisos
CREATE TABLE IF NOT EXISTS permisos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    modulo VARCHAR(50) NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de relación roles-permisos
CREATE TABLE IF NOT EXISTS rol_permisos (
    id SERIAL PRIMARY KEY,
    rol_id INTEGER NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permiso_id INTEGER NOT NULL REFERENCES permisos(id) ON DELETE CASCADE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(rol_id, permiso_id)
);

-- Tabla de usuarios (CORREGIDA - sin referencia circular)
CREATE TABLE IF NOT EXISTS usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(100) NOT NULL UNIQUE,
    contrasena TEXT NOT NULL,
    rol_id INTEGER NOT NULL REFERENCES roles(id),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20) NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo', 'inactivo'))
);

-- Tabla de visitantes
CREATE TABLE IF NOT EXISTS visitantes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    identificacion VARCHAR(50) NOT NULL UNIQUE,
    empresa VARCHAR(100),
    motivo TEXT,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20) NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo', 'inactivo'))
);

-- Tabla de credenciales
CREATE TABLE IF NOT EXISTS credenciales (
    id SERIAL PRIMARY KEY,
    visitante_id INTEGER NOT NULL REFERENCES visitantes(id) ON DELETE CASCADE,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    estado VARCHAR(20) DEFAULT 'activa' CHECK (estado IN ('activa', 'inactiva', 'expirada')),
    fecha_emision TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion TIMESTAMP,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de accesos
CREATE TABLE IF NOT EXISTS accesos (
    id SERIAL PRIMARY KEY,
    usuario_id INTEGER REFERENCES usuarios(id),
    visitante_id INTEGER REFERENCES visitantes(id),
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('entrada', 'salida')),
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    autorizado BOOLEAN DEFAULT TRUE,
    observaciones TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de alertas
CREATE TABLE IF NOT EXISTS alertas (
    id SERIAL PRIMARY KEY,
    descripcion VARCHAR(255) NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    nivel VARCHAR(20) DEFAULT 'medio' CHECK (nivel IN ('bajo', 'medio', 'alto')),
    usuario_id INTEGER REFERENCES usuarios(id),
    visitante_id INTEGER REFERENCES visitantes(id),
    leida BOOLEAN DEFAULT FALSE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================================
-- INSERTS BASE (CORREGIDOS PARA POSTGRESQL)
-- ==========================================================

-- Insertar roles (usando DO para evitar conflicts)
DO $$ 
BEGIN
    -- Insertar roles si no existen
    INSERT INTO roles (id, nombre, descripcion) VALUES
    (1, 'administrador', 'Administrador completo del sistema con todos los permisos'),
    (2, 'guardia', 'Personal de seguridad que gestiona accesos y visitantes'),
    (3, 'recepcion', 'Personal de recepción con permisos limitados'),
    (4, 'supervisor', 'Supervisor con permisos de visualización y reportes')
    ON CONFLICT (id) DO UPDATE SET 
        nombre = EXCLUDED.nombre,
        descripcion = EXCLUDED.descripcion;
END $$;

-- Insertar permisos
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
ON CONFLICT (nombre) DO NOTHING;

-- Asignar permisos a roles
DO $$
BEGIN
    -- Administrador: todos los permisos
    INSERT INTO rol_permisos (rol_id, permiso_id)
    SELECT 1, id FROM permisos
    ON CONFLICT (rol_id, permiso_id) DO NOTHING;

    -- Guardia
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
    ON CONFLICT (rol_id, permiso_id) DO NOTHING;

    -- Recepción
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
    ON CONFLICT (rol_id, permiso_id) DO NOTHING;

    -- Supervisor
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
    ON CONFLICT (rol_id, permiso_id) DO NOTHING;
END $$;

-- Insertar usuarios base (password hasheado con SHA256)
INSERT INTO usuarios (nombre, correo, contrasena, rol_id, estado) VALUES
('Administrador Principal', 'admin@controlacceso.com', encode(digest('admin123', 'sha256'), 'hex'), 1, 'activo'),
('Guardia de Seguridad', 'guardia@controlacceso.com', encode(digest('guardia123', 'sha256'), 'hex'), 2, 'activo'),
('Recepcionista', 'recepcion@controlacceso.com', encode(digest('recepcion123', 'sha256'), 'hex'), 3, 'activo'),
('Supervisor', 'supervisor@controlacceso.com', encode(digest('supervisor123', 'sha256'), 'hex'), 4, 'activo')
ON CONFLICT (correo) DO UPDATE SET
    nombre = EXCLUDED.nombre,
    contrasena = EXCLUDED.contrasena,
    rol_id = EXCLUDED.rol_id,
    estado = EXCLUDED.estado;

-- Insertar visitantes de ejemplo
INSERT INTO visitantes (nombre, identificacion, empresa, motivo, estado) VALUES
('Juan Pérez', 'V-12345678', 'Empresa ABC', 'Reunión de negocios', 'activo'),
('María García', 'V-87654321', 'Compañía XYZ', 'Entrega de documentos', 'activo'),
('Carlos López', 'V-11223344', 'Corporación DEF', 'Visita técnica', 'activo'),
('Ana Martínez', 'V-44332211', 'Industrias GHI', 'Entrevista de trabajo', 'activo')
ON CONFLICT (identificacion) DO NOTHING;

-- Insertar credenciales para visitantes
INSERT INTO credenciales (visitante_id, codigo, estado, fecha_expiracion)
SELECT 
    id, 
    UPPER(SUBSTRING(md5(random()::text || clock_timestamp()::text) FROM 1 FOR 8)),
    'activa',
    NOW() + INTERVAL '8 hours'
FROM visitantes
ON CONFLICT (codigo) DO NOTHING;

-- Insertar accesos de ejemplo
INSERT INTO accesos (usuario_id, visitante_id, tipo, autorizado, observaciones) VALUES
(2, 1, 'entrada', TRUE, 'Acceso normal'),
(2, 2, 'entrada', TRUE, 'Entrega de documentos'),
(2, 1, 'salida', TRUE, 'Salida registrada'),
(2, 3, 'entrada', TRUE, 'Visita técnica programada')
ON CONFLICT DO NOTHING;

-- Insertar alertas de ejemplo
INSERT INTO alertas (descripcion, nivel, usuario_id, leida) VALUES
('Intento de acceso fuera del horario permitido', 'medio', 2, FALSE),
('Visitante con credencial expirada intentó ingresar', 'alto', 2, FALSE),
('Acceso denegado por identificación no válida', 'alto', 2, FALSE)
ON CONFLICT DO NOTHING;

-- ==========================================================
-- ÍNDICES PARA MEJOR RENDIMIENTO
-- ==========================================================

-- Índices para usuarios
CREATE INDEX IF NOT EXISTS idx_usuarios_correo ON usuarios(correo);
CREATE INDEX IF NOT EXISTS idx_usuarios_rol_id ON usuarios(rol_id);
CREATE INDEX IF NOT EXISTS idx_usuarios_estado ON usuarios(estado);

-- Índices para visitantes
CREATE INDEX IF NOT EXISTS idx_visitantes_identificacion ON visitantes(identificacion);
CREATE INDEX IF NOT EXISTS idx_visitantes_estado ON visitantes(estado);
CREATE INDEX IF NOT EXISTS idx_visitantes_fecha_registro ON visitantes(fecha_registro);

-- Índices para credenciales
CREATE INDEX IF NOT EXISTS idx_credenciales_codigo ON credenciales(codigo);
CREATE INDEX IF NOT EXISTS idx_credenciales_estado ON credenciales(estado);
CREATE INDEX IF NOT EXISTS idx_credenciales_expiracion ON credenciales(fecha_expiracion);
CREATE INDEX IF NOT EXISTS idx_credenciales_visitante_id ON credenciales(visitante_id);

-- Índices para accesos
CREATE INDEX IF NOT EXISTS idx_accesos_fecha_hora ON accesos(fecha_hora);
CREATE INDEX IF NOT EXISTS idx_accesos_visitante_id ON accesos(visitante_id);
CREATE INDEX IF NOT EXISTS idx_accesos_usuario_id ON accesos(usuario_id);
CREATE INDEX IF NOT EXISTS idx_accesos_tipo ON accesos(tipo);

-- Índices para alertas
CREATE INDEX IF NOT EXISTS idx_alertas_fecha ON alertas(fecha);
CREATE INDEX IF NOT EXISTS idx_alertas_nivel ON alertas(nivel);
CREATE INDEX IF NOT EXISTS idx_alertas_leida ON alertas(leida);

-- Índices para rol_permisos
CREATE INDEX IF NOT EXISTS idx_rol_permisos_rol_id ON rol_permisos(rol_id);
CREATE INDEX IF NOT EXISTS idx_rol_permisos_permiso_id ON rol_permisos(permiso_id);

-- ==========================================================
-- VISTAS ÚTILES
-- ==========================================================

-- Vista para credenciales activas
CREATE OR REPLACE VIEW vista_credenciales_activas AS
SELECT 
    c.id,
    c.codigo,
    v.nombre as visitante_nombre,
    v.identificacion,
    v.empresa,
    c.fecha_emision,
    c.fecha_expiracion,
    c.estado
FROM credenciales c
JOIN visitantes v ON c.visitante_id = v.id
WHERE c.estado = 'activa' AND v.estado = 'activo';

-- Vista para reportes de acceso
CREATE OR REPLACE VIEW vista_reportes_acceso AS
SELECT 
    a.id,
    a.fecha_hora,
    a.tipo,
    a.autorizado,
    COALESCE(v.nombre, u.nombre) as persona_nombre,
    CASE 
        WHEN a.visitante_id IS NOT NULL THEN 'visitante'
        ELSE 'usuario'
    END as tipo_persona,
    a.observaciones
FROM accesos a
LEFT JOIN visitantes v ON a.visitante_id = v.id
LEFT JOIN usuarios u ON a.usuario_id = u.id;

-- ==========================================================
-- FUNCIONES ÚTILES
-- ==========================================================

-- Función para verificar credencial válida
CREATE OR REPLACE FUNCTION verificar_credencial(
    p_codigo VARCHAR
)
RETURNS TABLE(
    credencial_valida BOOLEAN,
    visitante_id INTEGER,
    visitante_nombre VARCHAR,
    mensaje VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        CASE 
            WHEN c.id IS NOT NULL AND c.estado = 'activa' AND c.fecha_expiracion > NOW() THEN TRUE
            ELSE FALSE
        END as credencial_valida,
        v.id as visitante_id,
        v.nombre as visitante_nombre,
        CASE 
            WHEN c.id IS NULL THEN 'Credencial no encontrada'
            WHEN c.estado != 'activa' THEN 'Credencial inactiva'
            WHEN c.fecha_expiracion <= NOW() THEN 'Credencial expirada'
            ELSE 'Credencial válida'
        END as mensaje
    FROM credenciales c
    JOIN visitantes v ON c.visitante_id = v.id
    WHERE c.codigo = p_codigo AND v.estado = 'activo';
END;
$$ LANGUAGE plpgsql;

-- Función para generar reporte de accesos por fecha
CREATE OR REPLACE FUNCTION generar_reporte_accesos(
    p_fecha_inicio TIMESTAMP,
    p_fecha_fin TIMESTAMP
)
RETURNS TABLE(
    fecha TIMESTAMP,
    tipo VARCHAR,
    total INTEGER,
    autorizados INTEGER,
    no_autorizados INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        DATE_TRUNC('day', a.fecha_hora) as fecha,
        a.tipo,
        COUNT(*) as total,
        COUNT(*) FILTER (WHERE a.autorizado = true) as autorizados,
        COUNT(*) FILTER (WHERE a.autorizado = false) as no_autorizados
    FROM accesos a
    WHERE a.fecha_hora BETWEEN p_fecha_inicio AND p_fecha_fin
    GROUP BY DATE_TRUNC('day', a.fecha_hora), a.tipo
    ORDER BY fecha DESC, a.tipo;
END;
$$ LANGUAGE plpgsql;

-- ==========================================================
-- CONFIGURACIÓN FINAL
-- ==========================================================

-- Establecer el search_path por defecto para el esquema
ALTER DATABASE current SET search_path TO control_acceso, public;

-- Comentarios descriptivos
COMMENT ON SCHEMA control_acceso IS 'Esquema para el sistema de control de acceso';
COMMENT ON TABLE usuarios IS 'Tabla de usuarios del sistema con sus credenciales y roles';

-- Grant permissions (ajustar según el usuario de Railway)
-- GRANT USAGE ON SCHEMA control_acceso TO tu_usuario;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA control_acceso TO tu_usuario;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA control_acceso TO tu_usuario;

-- Mensaje de confirmación
DO $$
BEGIN
    RAISE NOTICE '✅ Base de datos de Control de Acceso inicializada correctamente';
    RAISE NOTICE '📊 Esquema: control_acceso';
    RAISE NOTICE '👤 Usuario admin: admin@controlacceso.com / admin123';
END $$;
