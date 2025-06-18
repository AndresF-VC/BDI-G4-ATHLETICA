# Pipeline de Inserción de Datos SQL (`sql_insert_pipeline_auto.py`)

Este script automatiza la ejecución de un conjunto de archivos `.sql` en una base de datos PostgreSQL. Está diseñado para poblar de manera ordenada y robusta las tablas dentro de un esquema específico, como `olympus` en la base de datos `sports_db`.

## Requisitos Previos

- **Base de Datos y Esquema Creados**: Asegúrate de haber ejecutado los scripts DDL previos para crear la base de datos `sports_db` y el esquema `olympus`.
- **Usuario con Permisos**: El usuario de la base de datos (ej. `olympus_admin`) debe tener los permisos necesarios (`INSERT`, `SELECT`, etc.) sobre las tablas del esquema.
- **Archivos SQL**: Los archivos `.sql` a ejecutar deben estar en el directorio de datos (por defecto, `../../data`).
- **Dependencias de Python**:
  - `psycopg2-binary` (para la conexión con PostgreSQL)
  - `tqdm` (para las barras de progreso)

## Instalación de Dependencias

Instala las librerías necesarias con pip:

```bash
pip install psycopg2-binary tqdm
```

## Flujo de Ejecución

El pipeline realiza las siguientes acciones de forma automática:

1. **Conexión Segura**: Intenta conectarse a la base de datos con reintentos automáticos si la conexión falla inicialmente.
2. **Validación del Esquema**: Verifica que el esquema (ej. olympus) exista antes de continuar.
3. **Detección de Archivos**: Localiza todos los archivos con extensión `.sql` en el directorio especificado.
4. **Ejecución Ordenada**: Ejecuta los archivos en orden alfabético (por eso es importante nombrarlos con prefijos numéricos como `01_`, `02_`, etc.).
5. **Procesamiento Transaccional**: Cada archivo se ejecuta dentro de su propia transacción. Si un comando dentro de un archivo falla, todos los cambios de ese archivo se revierten (ROLLBACK), garantizando la integridad de los datos.
6. **Reporte Final**: Informa cuántos archivos se ejecutaron con éxito.

## Ejecución del Pipeline

Para ejecutar el pipeline, utiliza el siguiente comando, reemplazando los valores necesarios.

**Comando General:**

```bash
python sql_insert_pipeline_auto.py --user <tu_usuario> --password "<tu_contraseña>" --db-name sports_db --sql-dir <ruta_a_los_datos>
```

**Ejemplo Práctico:**

```bash
python sql_insert_pipeline_auto.py --user olympus_admin --password "olympus_password" --db-name sports_db --sql-dir ../../data --delay 0.5
```

## Salida Esperada en la Consola

La ejecución mostrará un log detallado y barras de progreso para cada archivo:

```
2024-10-27 11:00:01,123 - sql_insert_pipeline - INFO - Directorio SQL: /path/to/project/data
2024-10-27 11:00:01,125 - sql_insert_pipeline - INFO - Conectado a PostgreSQL en intento 1
2024-10-27 11:00:01,150 - sql_insert_pipeline - INFO - Existe esquema 'olympus': True
01_regions.sql: 100%|█████████████████████████████████| 1/1 [00:00<00:00, 150.50it/s]
2024-10-27 11:00:01,200 - sql_insert_pipeline - INFO - Ejecutado 1 statements en /path/to/project/data/01_regions.sql
02_countries.sql: 100%|███████████████████████████████| 5/5 [00:00<00:00, 310.21it/s]
2024-10-27 11:00:01,750 - sql_insert_pipeline - INFO - Ejecutado 5 statements en /path/to/project/data/02_countries.sql
...
2024-10-27 11:00:15,500 - sql_insert_pipeline - INFO - Completado: 10/10 archivos ejecutados exitosamente
```

## Parámetros Disponibles del Pipeline

| Argumento        | Descripción                                                        | Valor por Defecto | Requerido |
|------------------|---------------------------------------------------------------------|--------------------|-----------|
| `--host`         | Host del servidor PostgreSQL.                                       | `localhost`        | No        |
| `--port`         | Puerto del servidor PostgreSQL.                                     | `5432`             | No        |
| `--user`         | Nombre de usuario para la conexión a PostgreSQL.                   | N/A                | Sí        |
| `--password`     | Contraseña del usuario.                                             | N/A                | Sí        |
| `--db-name`      | Nombre de la base de datos a la que conectarse.                    | N/A                | Sí        |
| `--schema-name`  | Nombre del esquema donde se encuentran las tablas.                 | `olympus`          | No        |
| `--sql-dir`      | Directorio que contiene los archivos `.sql`.                       | `../../data`       | No        |
| `--delay`        | Retraso en segundos entre la ejecución de cada archivo.            | `1.0`              | No        |

## Validación de Datos Insertados

Para verificar que todos los datos se han cargado correctamente:

1. **Conéctate con `psql`:**

```bash
psql -h localhost -p 5432 -U sports_admin -d sports_db
```

2. **Ejecuta la consulta:**

```sql
SELECT table_name, table_rows
FROM information_schema.tables
WHERE table_schema = 'olympus'
ORDER BY table_name;
```

> Nota: `table_rows` es una estimación en PostgreSQL. Para un conteo exacto, usa `SELECT COUNT(*)` en cada tabla.

## Características Clave del Pipeline

- **Robustez**: Reintentos de conexión con espera exponencial.
- **Integridad de Datos**: Uso de transacciones por archivo para evitar cargas parciales.
- **Automatización**: Ejecuta todos los scripts de un directorio en el orden correcto sin intervención manual.
- **Feedback Visual**: Barras de progreso (`tqdm`) para monitorear la carga de cada archivo.
- **Flexibilidad**: Múltiples parámetros para adaptar la ejecución a diferentes entornos.
- **Logging Detallado**: Registros claros de cada paso para facilitar la depuración.

## Estructura de Archivos Esperada

```
sports-data-project/
├── data/
│   ├── 01_regions.sql
│   ├── 02_countries.sql
│   ├── 03_sports.sql
│   └── ... (otros archivos de datos .sql)
└── pipelines/
    └── insert_data/
        ├── sql_insert_pipeline_auto.py
        └── README.md
```

## Solución de Problemas Comunes

- **Error `schema <schema_name> no existe`**: Asegúrate de haber ejecutado los scripts DDL iniciales para crear la base de datos y el esquema.
- **Error de Conexión**: Verifica host, puerto, usuario y contraseña, y que el servidor PostgreSQL esté activo.
- **Fallo en un Archivo SQL**: El log indicará el archivo y el error específico (pgerror). Revisa la sintaxis del archivo `.sql`.
- **Archivos no encontrados**: Verifica que la ruta en `--sql-dir` sea correcta o que existan los archivos en `../../data`.