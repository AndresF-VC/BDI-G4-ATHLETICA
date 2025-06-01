#!/usr/bin/env python3

import os
import sys
import argparse
import psycopg2
from psycopg2 import sql
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
import logging

# Configuración básica del logger
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger('sports_pipeline')

def parse_args():
    parser = argparse.ArgumentParser(description="Pipeline de creación de base de datos deportiva")
    parser.add_argument('--host', default='localhost')
    parser.add_argument('--port', type=int, default=5432)
    parser.add_argument('--user', required=True)
    parser.add_argument('--password', required=True)
    parser.add_argument('--db-name', default='sports_db')
    parser.add_argument('--schema-name', default='olympus')
    parser.add_argument('--sql-dir', default='.')
    parser.add_argument('--use-sql-for-db-creation', action='store_true')
    return parser.parse_args()

def connect_postgres(host, port, user, password, dbname="postgres"):
    try:
        conn = psycopg2.connect(
            host=host, port=port, user=user, password=password, dbname=dbname
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        return conn
    except Exception as e:
        logger.error(f"Error conectando a PostgreSQL: {e}")
        sys.exit(1)

def database_exists(conn, db_name):
    with conn.cursor() as cur:
        cur.execute("SELECT 1 FROM pg_database WHERE datname = %s", (db_name,))
        return cur.fetchone() is not None

def create_database(conn, db_name):
    if database_exists(conn, db_name):
        logger.info(f"La base de datos '{db_name}' ya existe.")
        return
    with conn.cursor() as cur:
        cur.execute(sql.SQL("CREATE DATABASE {}").format(sql.Identifier(db_name)))
        logger.info(f"Base de datos '{db_name}' creada.")

def execute_sql_file(conn, filepath):
    logger.info(f"Ejecutando archivo: {filepath}")
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            sql_code = f.read()
    except UnicodeDecodeError:
        with open(filepath, 'r', encoding='latin-1') as f:
            sql_code = f.read()

    statements = []
    buffer = ""
    for line in sql_code.splitlines():
        line = line.strip()
        if not line or line.startswith('--'):
            continue
        buffer += " " + line
        if line.endswith(";"):
            statements.append(buffer.strip())
            buffer = ""

    with conn.cursor() as cur:
        for i, stmt in enumerate(statements):
            try:
                cur.execute(stmt)
                logger.info(f"Sentencia {i+1}/{len(statements)} ejecutada con éxito.")
            except Exception as e:
                logger.error(f"Error en sentencia {i+1}: {e}")
                sys.exit(1)

def main():
    args = parse_args()

    sql_dir = os.path.abspath(args.sql_dir)
    db_creation_file = os.path.join(sql_dir, '01_create_database.sql')
    tables_file = os.path.join(sql_dir, '02_create_tables.sql')

    if args.use_sql_for_db_creation:
        conn = connect_postgres(args.host, args.port, args.user, args.password)
        if os.path.exists(db_creation_file):
            execute_sql_file(conn, db_creation_file)
        else:
            logger.warning("Archivo 01_create_database.sql no encontrado. Creando base de datos desde código.")
            create_database(conn, args.db_name)
        conn.close()
    else:
        conn = connect_postgres(args.host, args.port, args.user, args.password)
        create_database(conn, args.db_name)
        conn.close()

    conn = connect_postgres(args.host, args.port, args.user, args.password, args.db_name)
    if os.path.exists(tables_file):
        execute_sql_file(conn, tables_file)
    else:
        logger.error(f"Archivo 02_create_tables.sql no encontrado en {sql_dir}")
        sys.exit(1)
    conn.close()
    logger.info("Pipeline completado correctamente.")

if __name__ == '__main__':
    main()