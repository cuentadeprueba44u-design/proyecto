#!/usr/bin/env python3
"""
Script de inicialización de la base de datos (PostgreSQL)

Notas:
- Si usas Render, define la variable de entorno DATABASE_URL con la External Database URL.
- Algunos servicios no permiten crear la base de datos desde el usuario proporcionado; en tal caso importa el SQL directamente desde el panel de la base de datos o solicita permisos.
"""
import os
import psycopg
from psycopg import sql
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

    # Preparar conexión: preferir DATABASE_URL
    conn = None
    try:
        if DATABASE_URL:
            # psycopg.connect acepta la DATABASE_URL directamente
            conn = psycopg.connect(DATABASE_URL)
        else:
            cfg = get_db_config()
            conn = psycopg.connect(**cfg)

        print("✅ Conectado a la base de datos")

        # Ejecutar script SQL
        sql_path = 'control_acceso_3.sql'
        if os.path.exists(sql_path):
            ejecutar_sql(conn, sql_path)
        else:
            print("❌ Archivo SQL no encontrado")
            print("💡 Asegúrate de que el archivo 'control_acceso_3.sql' esté en el directorio raíz")

    except Exception as e:
        print(f"❌ Error de conexión o ejecución: {e}")
        print("� Verifica que la variable DATABASE_URL esté definida y sea correcta, o que la base de datos sea accesible.")
    finally:
        if conn:
            conn.close()


if __name__ == '__main__':
    main()
