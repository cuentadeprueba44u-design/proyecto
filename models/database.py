import hashlib
import psycopg
from psycopg.rows import dict_row
from config import get_db_config


class Database:
    def __init__(self):
        # usar configuración desde config.get_db_config()
        self.config = get_db_config()

    def conectar(self):
        """Establecer conexión con la base de datos PostgreSQL"""
        try:
            conn = psycopg.connect(**self.config)
            return conn
        except Exception as e:
            print(f"Error al conectar a PostgreSQL: {e}")
            return None

    @staticmethod
    def hash_contrasena(contrasena):
        """Hashear contraseña usando SHA-256"""
        return hashlib.sha256(contrasena.encode()).hexdigest()

    @staticmethod
    def verificar_contrasena(contrasena, hash_almacenado):
        """Verificar contraseña hasheada"""
        return Database.hash_contrasena(contrasena) == hash_almacenado

def obtener_permisos_usuario(usuario_id):
    """Obtener todos los permisos de un usuario basado en su rol"""
    db = Database()
    conn = db.conectar()
    if not conn:
        return []

    try:
        # usar cursor con filas tipo dict (psycopg3)
        with conn.cursor(row_factory=dict_row) as cursor:
            cursor.execute("""
                SELECT p.nombre, p.modulo
                FROM usuarios u
                JOIN roles r ON u.rol_id = r.id
                JOIN rol_permisos rp ON r.id = rp.rol_id
                JOIN permisos p ON rp.permiso_id = p.id
                WHERE u.id = %s AND u.estado = 'activo'
            """, (usuario_id,))
            permisos = cursor.fetchall()
            return [f"{p['modulo']}.{p['nombre']}" for p in permisos]
    except Exception as e:
        print(f"Error al obtener permisos: {e}")
        return []
    finally:
        conn.close()

def tiene_permiso(usuario_id, permiso_requerido):
    """Verificar si un usuario tiene un permiso específico"""
    permisos = obtener_permisos_usuario(usuario_id)
    return permiso_requerido in permisos

def obtener_usuario_actual(usuario_id):
    """Obtener datos del usuario actual por id (retorna None si no existe o está inactivo)"""
    db = Database()
    conn = db.conectar()
    if not conn:
        return None

    try:
        with conn.cursor(row_factory=dict_row) as cursor:
            cursor.execute("""
                SELECT u.*, r.nombre as rol_nombre, r.descripcion as rol_descripcion
                FROM usuarios u 
                JOIN roles r ON u.rol_id = r.id 
                WHERE u.id = %s AND u.estado = 'activo'
            """, (usuario_id,))
            usuario = cursor.fetchone()
            if usuario:
                usuario = dict(usuario)
                usuario['permisos'] = obtener_permisos_usuario(usuario['id'])
            return usuario
    except Exception as e:
        print(f"Error al obtener usuario actual: {e}")
        return None
    finally:
        conn.close()
