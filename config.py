import os
from datetime import timedelta
from urllib.parse import urlparse

# Configuración de la base de datos
# Preferir DATABASE_URL (p. ej. la proveída por Render). Si no existe, usar valores individuales.
DATABASE_URL = os.getenv('DATABASE_URL') or os.getenv('DATABASE_URI')

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

    # Fallback para desarrollo (antes con MySQL)
    return {
        'dbname': os.getenv('DB_NAME', 'control_acceso'),
        'user': os.getenv('DB_USER', 'postgres'),
        'password': os.getenv('DB_PASSWORD', ''),
        'host': os.getenv('DB_HOST', 'localhost'),
        'port': int(os.getenv('DB_PORT', 5432))
    }

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

# Configuración de la aplicación
SECRET_KEY = 'clave_secreta_super_segura_mejorada_2024'
DEBUG = True

# Configuración de sesiones y cookies
PERMANENT_SESSION_LIFETIME = timedelta(hours=24)
SESSION_COOKIE_SECURE = False  # True en producción con HTTPS
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = 'Lax'

# Configuración de horarios
HORARIOS_ACCESO = {
    'hora_inicio': '08:00',
    'hora_fin': '18:00'
}

# Configuración de credenciales
DURACION_CREDENCIAL_HORAS = 8

# Configuración de seguridad
MAX_LOGIN_ATTEMPTS = 5
LOCKOUT_TIME = 15  # minutos
