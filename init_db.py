#!/usr/bin/env python3
"""
Script de inicialización de la base de datos (PostgreSQL)

Notas:
- Si usas Render, define la variable de entorno DATABASE_URL con la External Database URL.
- Algunos servicios no permiten crear la base de datos desde el usuario proporcionado; en tal caso importa el SQL directamente desde el panel de la base de datos o solicita permisos.
"""
import os
import psycopg2
from psycopg2 import sql
from config import DATABASE_URL, get_db_config


def ejecutar_sql(conexion, sql_file):
    """Ejecutar archivo SQL (separa por ';' y ejecuta sentencias no vacías)."""
    try:
        cursor = conexion.cursor()

        with open(sql_file, 'r', encoding='utf-8') as file:
            sql_script = file.read()

        # Ejecutar cada sentencia por separado
        statements = [s.strip() for s in sql_script.split(';') if s.strip()]
        for statement in statements:
            try:
                cursor.execute(statement)
            except Exception as e:
                # Mostrar la sentencia problemática para debugging y continuar
                print(f"❌ Error ejecutando sentencia: {e}\n--> Sentencia: {statement[:200]}...")

        conexion.commit()
        print(f"✅ Script {sql_file} ejecutado correctamente")

    except Exception as e:
        print(f"❌ Error ejecutando {sql_file}: {e}")
        conexion.rollback()
    finally:
        cursor.close()


def main():
    print("🚀 Inicializando Sistema de Control de Acceso (PostgreSQL)")
    print("=" * 50)


    # Preparar conexión: Railway/Postgres
    conn = None
    try:
        cfg = get_db_config()
        # Añadir sslmode=require para Railway
        cfg['sslmode'] = 'require'
        conn = psycopg2.connect(**cfg)

        print("✅ Conectado a la base de datos Railway/Postgres")

        # Ejecutar script SQL correcto
        sql_path = 'control_acceso_postgres.sql'
        if os.path.exists(sql_path):
            ejecutar_sql(conn, sql_path)
        else:
            print("❌ Archivo SQL no encontrado")
            print("💡 Asegúrate de que el archivo 'control_acceso_postgres.sql' esté en el directorio raíz")

    except Exception as e:
        print(f"❌ Error de conexión o ejecución: {e}")
        print("� Verifica que las credenciales Railway sean correctas y que la base de datos sea accesible.")
    finally:
        if conn:
            conn.close()


if __name__ == '__main__':
    main()
