# Pipeline de Creación de la Base de Datos "Olympus"

Este conjunto de scripts de Python automatiza la creación y configuración de la base de datos PostgreSQL para el proyecto de gestión atlética "Olympus". Los scripts están diseñados para crear la base de datos, el esquema y todas las tablas necesarias de forma rápida y reproducible.

### Requisitos

*   Python 3.6 o superior
*   Biblioteca `psycopg2` para la conexión con PostgreSQL

### Instalación

1.  Asegúrate de tener Python instalado en tu sistema.
2.  Instala las dependencias necesarias:
    ```bash
    pip install psycopg2-binary
    ```

### Estructura de Archivos SQL

El pipeline busca los siguientes archivos SQL en el directorio especificado con `--sql-dir` (por defecto, la carpeta `sql/ddl/` del proyecto):

*   `01_create_database.sql`: Script que crea la base de datos y el esquema (y opcionalmente el usuario de la aplicación).
*   `02_create_tables.sql`: Script que crea todas las tablas dentro del esquema `olympus`.

---

## 🔄 Ejecución del Pipeline

Para ejecutar los scripts, navega en tu terminal a la carpeta donde se encuentran: `.../scripts/pipelines/create_database/`. Si usas un entorno virtual, asegúrate de que esté activado.

### Paso 0: Probar la Conexión (Opcional pero recomendado)

Antes de ejecutar el pipeline principal, puedes usar `test_connection.py` para verificar que tus credenciales y la configuración de red son correctas.

**Comando:**
```bash
python test_connection.py localhost 5432 postgres "tu_contraseña_de_postgres"

Salida Esperada:

=== Testing PostgreSQL Connection ===
Host: localhost
Port: 5432
User: postgres
Password: *************************
...

Attempting connection method 1 (keyword arguments)...
✅ Connection successful (Method 1)!

Attempting connection method 2 (connection string)...
✅ Connection successful (Method 2)!

Attempting connection method 3 (URI)...
✅ Connection successful (Method 3)!

🧩 Paso 1: Crear la Base de Datos y el Esquema (como postgres)
Este paso se ejecuta con un usuario administrador (como postgres) para crear la nueva base de datos (sports_db), el esquema (olympus) y el usuario de la aplicación.
Comando:

python sports_pipeline.py --user postgres --password "tu_contraseña_de_postgres" --db-name postgres --sql-dir ../../sql/ddl --use-sql-for-db-creation

Explicación del Comando:
--user postgres: Se usa el superusuario de PostgreSQL.
--db-name postgres: Nos conectamos a la base de datos postgres por defecto para poder crear una nueva.
--sql-dir ../../sql/ddl: Indicamos la ruta relativa a la carpeta que contiene los scripts DDL.
--use-sql-for-db-creation: Le decimos al pipeline que ejecute 01_create_database.sql.

Salida Esperada en la Consola:

2024-10-27 10:30:15,123 - sports_pipeline - INFO - Ejecutando archivo: ../../sql/ddl\01_create_database.sql
2024-10-27 10:30:15,125 - sports_pipeline - INFO - Sentencia 1/X ejecutada con éxito.
...
2024-10-27 10:30:15,130 - sports_pipeline - INFO - Sentencia X/X ejecutada con éxito.
2024-10-27 10:30:15,135 - sports_pipeline - INFO - Pipeline completado correctamente.

🧩 Paso 2: Crear las Tablas (como usuario de la aplicación)
Una vez creada la base de datos, nos conectamos con el nuevo usuario (ej. olympus_admin, asumiendo que fue creado en el paso 1) para crear las tablas.

python sports_pipeline.py --user olympus_admin --password "contraseña_del_nuevo_usuario" --db-name sports_db --schema-name olympus --sql-dir ../../sql/ddl

Explicación del Comando:
--user olympus_admin: Usamos el nuevo usuario específico de la aplicación.
--db-name sports_db: Nos conectamos directamente a la base de datos recién creada.
En este paso no se usa --use-sql-for-db-creation, por lo que el script omitirá 01_create_database.sql y ejecutará 02_create_tables.sql para crear las tablas.

Salida Esperada en la Consola:

2024-10-27 10:35:45,456 - sports_pipeline - INFO - La base de datos 'sports_db' ya existe.
2024-10-27 10:35:45,500 - sports_pipeline - INFO - Ejecutando archivo: ../../sql/ddl\02_create_tables.sql
2024-10-27 10:35:45,510 - sports_pipeline - INFO - Sentencia 1/Y ejecutada con éxito.
...
2024-10-27 10:35:45,600 - sports_pipeline - INFO - Sentencia Y/Y ejecutada con éxito.
2024-10-27 10:35:45,601 - sports_pipeline - INFO - Pipeline completado correctamente.

Opciones Disponibles del Pipeline
Argumento	Descripción	Valor por Defecto
--host	Host del servidor PostgreSQL.	localhost
--port	Puerto del servidor PostgreSQL.	5432
--user	(Obligatorio) Nombre de usuario para la conexión.	N/A
--password	(Obligatorio) Contraseña del usuario.	N/A
--db-name	Nombre de la base de datos a crear o a la que conectarse.	sports_db
--schema-name	Nombre del esquema a utilizar.	olympus
--sql-dir	Directorio donde se encuentran los archivos .sql.	.
--use-sql-for-db-creation	Flag para indicar que se debe ejecutar 01_create_database.sql.	False

Notas Importantes
Seguridad: El primer paso requiere un usuario con privilegios de superusuario (postgres), mientras que el segundo debe usar el usuario con permisos limitados creado para la aplicación.
Rutas: Asegúrate de que la ruta en --sql-dir sea la correcta desde la ubicación del script.
Idempotencia: El script está diseñado para no fallar si la base de datos ya existe, simplemente lo notificará y continuará con los siguientes pasos.