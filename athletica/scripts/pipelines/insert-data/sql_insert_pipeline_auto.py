#!/usr/bin/env python3
import os
import sys
import argparse
import psycopg2
import time
import logging
from psycopg2 import sql, errors
from psycopg2.extras import execute_values
from tqdm import tqdm

# Configuración de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger('sql_insert_pipeline')


def parse_arguments():
    parser = argparse.ArgumentParser(description='Pipeline para insertar SQL dumps en PostgreSQL (esquema olympus)')
    parser.add_argument('--host',       default='localhost', help='Host de PostgreSQL (por defecto: localhost)')
    parser.add_argument('--port',       default=5432, type=int, help='Puerto de PostgreSQL (por defecto: 5432)')
    parser.add_argument('--user',       required=True, help='Usuario de PostgreSQL')
    parser.add_argument('--password',   required=True, help='Contraseña de PostgreSQL')
    parser.add_argument('--db-name',    required=True, help='Nombre de la base de datos')
    parser.add_argument('--schema-name', default='olympus', help='Nombre del esquema (por defecto: olympus)')
    parser.add_argument('--sql-dir',    default=None, help='Directorio con archivos .sql (por defecto: data directory)')
    parser.add_argument('--delay',      type=float, default=1.0, help='Retraso entre ficheros en segundos (por defecto: 1.0)')
    return parser.parse_args()


def find_sql_directory(provided_dir: str) -> str:
    """
    Retorna el directorio donde están los .sql; si no se pasó, busca ../../data
    """
    if provided_dir and os.path.isdir(provided_dir):
        return os.path.abspath(provided_dir)
    # Ubicación por defecto: dos niveles arriba, carpeta 'data'
    base = os.path.dirname(os.path.realpath(__file__))
    default_dir = os.path.normpath(os.path.join(base, '..', '..', 'data'))
    if os.path.isdir(default_dir):
        return default_dir
    logger.error(f"No se encontró directorio de SQL en {provided_dir or default_dir}")
    sys.exit(1)


def connect_postgres(args) -> psycopg2.extensions.connection:
    for attempt in range(3):
        try:
            conn = psycopg2.connect(
                host=args.host,
                port=args.port,
                user=args.user,
                password=args.password,
                dbname=args.db_name,
                connect_timeout=10
            )
            logger.info(f"Conectado a PostgreSQL en intento {attempt+1}")
            return conn
        except (psycopg2.OperationalError, psycopg2.InterfaceError) as e:
            logger.warning(f"Error conexión intento {attempt+1}: {e}")
            time.sleep(2 ** attempt)
    logger.error("No se pudo conectar a la base de datos")
    sys.exit(1)


def schema_exists(conn, schema_name: str) -> bool:
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT 1 FROM pg_namespace WHERE nspname = %s", (schema_name,)
            )
            exists = cur.fetchone() is not None
            logger.info(f"Existe esquema '{schema_name}': {exists}")
            return exists
    except Exception as e:
        logger.error(f"Error comprobando esquema: {e}")
        return False


def validate_sql_file(path: str) -> bool:
    if not os.path.isfile(path):
        logger.error(f"No encontrado: {path}")
        return False
    if os.path.getsize(path) == 0:
        logger.warning(f"Archivo vacío: {path}")
        return False
    return True


def execute_sql_file(conn, path: str) -> bool:
    if not validate_sql_file(path):
        return False
    try:
        with open(path, 'r', encoding='utf-8') as f:
            sql_text = f.read()
    except UnicodeDecodeError:
        with open(path, 'r', encoding='latin-1') as f:
            sql_text = f.read()

    # Separar por ';' manteniendo transacciones completas
    statements = []
    buf = ''
    for line in sql_text.splitlines():
        if line.strip().startswith('--') or not line.strip():
            continue
        buf += line + '\n'
        if line.strip().endswith(';'):
            statements.append(buf)
            buf = ''
    if not statements:
        logger.warning(f"Sin declaraciones SQL en {path}")
        return True

    with conn.cursor() as cur:
        with tqdm(statements, desc=os.path.basename(path), leave=False) as bar:
            for stmt in bar:
                try:
                    cur.execute(stmt)
                except errors.Error as e:
                    logger.error(f"Error en {path}: {e.pgerror}")
                    conn.rollback()
                    return False
    conn.commit()
    logger.info(f"Ejecutado {len(statements)} statements en {path}")
    return True


def run():
    args = parse_arguments()
    sql_dir = find_sql_directory(args.sql_dir)
    logger.info(f"Directorio SQL: {sql_dir}")

    conn = connect_postgres(args)
    if not schema_exists(conn, args.schema_name):
        logger.error(f"Esquema '{args.schema_name}' no existe. Abortando.")
        sys.exit(1)

    # Listar todos los .sql ordenados
    files = sorted(
        f for f in os.listdir(sql_dir)
        if f.lower().endswith('.sql')
    )
    if not files:
        logger.error(f"No hay archivos .sql en {sql_dir}")
        sys.exit(1)

    success = 0
    for idx, filename in enumerate(files, start=1):
        fullpath = os.path.join(sql_dir, filename)
        if execute_sql_file(conn, fullpath):
            success += 1
        else:
            logger.error(f"Fallo al procesar {filename}")
            break
        # Delay salvo último
        if idx < len(files):
            time.sleep(args.delay)

    logger.info(f"Completado: {success}/{len(files)} archivos ejecutados exitosamente")
    conn.close()


if __name__ == '__main__':
    run()
