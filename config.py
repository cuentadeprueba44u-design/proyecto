import os
from datetime import timedelta
from urllib.parse import urlparse

# Configuración de la base de datos
# Preferir DATABASE_URL (p. ej. la proveída por Render). Si no existe, usar valores individuales.
DEFAULT_RENDER_EXTERNAL = 'postgresql://hydra:ONikfvcWFgK25RXKhsTCKczSIlOcpgpA@dpg-d45rep6uk2gs73coqjf0-a.oregon-postgres.render.com/control_acceso_postgreslq'
DATABASE_URL = os.getenv('DATABASE_URL') or os.getenv('DATABASE_URI') or os.getenv('DEFAULT_DATABASE_URL') or DEFAULT_RENDER_EXTERNAL

def get_db_config():
    """Retorna un diccionario con la configuración de conexión para psycopg2.
    Si existe DATABASE_URL, la parsea. Si no, toma valores individuales (útil para desarrollo local).
    """
    if DATABASE_URL:
        # Ejemplo: postgresql://user:pass@host:5432/dbname
        parsed = urlparse(DATABASE_URL)
        return {
            'dbname': parsed.path.lstrip('/'),
            'user': parsed.username,
            'password': parsed.password,
            'host': parsed.hostname,
            'port': parsed.port or 5432
        }

    # Fallback para desarrollo / valores por defecto (se configuran con las credenciales de Render si no hay variables de entorno)
    return {
        'dbname': os.getenv('DB_NAME', 'control_acceso_postgreslq'),
        'user': os.getenv('DB_USER', 'hydra'),
        'password': os.getenv('DB_PASSWORD', 'ONikfvcWFgK25RXKhsTCKczSIlOcpgpA'),
        'host': os.getenv('DB_HOST', 'dpg-d45rep6uk2gs73coqjf0-a.oregon-postgres.render.com'),
        'port': int(os.getenv('DB_PORT', 5432))
    }


def get_database_url():
    """Retorna la DATABASE_URL si está definida; si no, la construye a partir de variables individuales.

    Resultado: cadena tipo 'postgresql://user:pass@host:port/dbname'
    """
    if DATABASE_URL:
        return DATABASE_URL

    cfg = get_db_config()
    user = cfg.get('user') or ''
    password = cfg.get('password') or ''
    host = cfg.get('host') or 'localhost'
    port = cfg.get('port') or 5432
    dbname = cfg.get('dbname') or ''
    # escape básica (no muy robusta) - en sistemas reales usar urllib.parse
    return f"postgresql://{user}:{password}@{host}:{port}/{dbname}"

# Configuración de la aplicación
SECRET_KEY = os.getenv('SECRET_KEY', 'clave_secreta_super_segura_mejorada_2024')
DEBUG = os.getenv('FLASK_DEBUG', '1') != '0'

# Configuración de sesiones y cookies
PERMANENT_SESSION_LIFETIME = timedelta(hours=int(os.getenv('SESSION_LIFETIME_HOURS', '24')))
SESSION_COOKIE_SECURE = os.getenv('SESSION_COOKIE_SECURE', '0') == '1'
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = os.getenv('SESSION_COOKIE_SAMESITE', 'Lax')

# Configuración de horarios
HORARIOS_ACCESO = {
    'hora_inicio': os.getenv('HORA_INICIO', '08:00'),
    'hora_fin': os.getenv('HORA_FIN', '18:00')
}

# Configuración de credenciales
DURACION_CREDENCIAL_HORAS = int(os.getenv('DURACION_CREDENCIAL_HORAS', '8'))

# Configuración de seguridad
MAX_LOGIN_ATTEMPTS = int(os.getenv('MAX_LOGIN_ATTEMPTS', '5'))
LOCKOUT_TIME = int(os.getenv('LOCKOUT_TIME_MIN', '15'))  # minutos
 
