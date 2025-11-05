# Sistema de Control de Acceso

Sistema web desarrollado en Flask para la gestión y control de acceso de visitantes.

## 🚀 Características

- **Autenticación segura** con sistema de roles y permisos
- **Gestión de visitantes** con credenciales temporales
- **Control de acceso** en tiempo real con registro de entradas/salidas
- **Sistema de alertas** para eventos importantes
- **Reportes** en PDF y CSV
- **Interfaz responsive** con Bootstrap 5
- **Cookies de sesión** con duración configurable

## 🛠️ Instalación

### Prerrequisitos
- Python 3.8+
- PostgreSQL (o una base de datos PostgreSQL en un servicio como Render)
- pip (gestor de paquetes de Python)

### Dependencias
Instalar dependencias:

```powershell
pip install -r requirements.txt
```

### Configurar conexión a la base de datos
Este proyecto ahora usa PostgreSQL. Puedes configurar la conexión de dos formas:

- Definir la variable de entorno `DATABASE_URL` (recomendada). Por ejemplo, para Render pega la "External Database URL" tal cual:

	`postgresql://hydra:janOddtOHJ0WZvcrHwsNZq7jFcN4JIvs@dpg-d45e15p5pdvs73c00n70-a.oregon-postgres.render.com/control_acceso`

- O bien definir variables individuales: `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`.

### Inicializar la base de datos
Si tienes acceso al servidor PostgreSQL con el usuario adecuado, puedes ejecutar el script de inicialización SQL del proyecto:

```powershell
# Establecer DATABASE_URL en PowerShell (ejemplo)
$env:DATABASE_URL = "postgresql://hydra:janOddtOHJ0WZvcrHwsNZq7jFcN4JIvs@dpg-d45e15p5pdvs73c00n70-a.oregon-postgres.render.com/control_acceso";
python init_db.py
```

Nota: Algunos servicios gestionados no permiten crear bases de datos desde el usuario proporcionado. Si al ejecutar `init_db.py` falla con permisos, importa el archivo `control_acceso_3.sql` desde el panel de administración de la base de datos de tu proveedor (p. ej. Render) o crea las tablas manualmente.

### Conectar desde psql (opcional)
Si quieres conectarte con psql desde tu máquina (ejemplo en PowerShell):

```powershell
$env:PGPASSWORD = 'janOddtOHJ0WZvcrHwsNZq7jFcN4JIvs';
psql -h dpg-d45e15p5pdvs73c00n70-a.oregon-postgres.render.com -U hydra control_acceso
```

### Variables en Render
En el panel de Render, crea una Environment Variable llamada `DATABASE_URL` y pega la "External Database URL". Después despliega la aplicación; Render inyectará la variable y la app usará esa conexión.
