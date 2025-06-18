# BDI-G4-ATHLETICA

# BDI-G4-Athletica

🚀 **Proyecto:** Base de Datos I - Sistema de Gestión Atlética "Olympus"
**Desarrollador:** [Equipo Nucita]
**Repositorio:** `BDI-G4-Athletica` 📂
**Creado:** [01/06/2025] 🗓️
**Última Actualización:** [18/06/2025] ✨

---

## Estructura del Proyecto

Este proyecto está organizado en una estructura de carpetas clara y modular para facilitar el desarrollo, la gestión y el mantenimiento de la base de datos.

### `docs/`

*   **Propósito:** Centraliza toda la documentación funcional y técnica del proyecto. Esencial para entender el diseño y las reglas de negocio.

*   **Contenido:**
    *   `Normalizacion-4fn.xlsx`: Documento que detalla el proceso de normalización de la base de datos hasta la Cuarta Forma Normal (4NF).
    *   `diccionario_athletica_final.xlsx`: Diccionario de datos que define cada tabla, columna, tipo de dato, y sus respectivas descripciones.

### `models/`

*   **Propósito:** Almacena los modelos de la base de datos en sus diferentes etapas de diseño: Conceptual, Lógico y Físico.

*   **Subcarpetas:**
    *   **`ERD/`**: Contiene el Diagrama Entidad-Relación (ERD), que representa el modelo conceptual inicial del sistema.
    *   **`LDM/`**: Incluye el Modelo Lógico de Datos (LDM), donde se definen las entidades, atributos y relaciones sin depender de un motor de base de datos específico.
    *   **`PDM/`**: Contiene el Modelo Físico de Datos (PDM), que es la representación concreta del modelo para su implementación en un SGBD específico, incluyendo tipos de datos, índices y restricciones.

### `scripts/`

*   **Propósito:** Contiene todo el código ejecutable del proyecto, incluyendo scripts de datos, pipelines de automatización y scripts SQL puros.

*   **Subcarpetas:**
    *   **`data/`**: Scripts SQL con sentencias `INSERT` para la carga de datos iniciales (seed data). Cada archivo corresponde a una tabla específica del sistema Olympus.
    *   **`pipelines/`**: Scripts de automatización en Python para gestionar el ciclo de vida de la base de datos.
        *   `create_database/`: Scripts para la creación y configuración inicial.
            *   `sports_pipeline.py`: Pipeline principal para la construcción de la base de datos.
            *   `test_connection.py`: Script de utilidad para verificar la conexión a la base de datos.
        *   `insert-data/`: Lógica para la carga de datos automatizada.
            *   `sql_insert_pipeline_auto.py`: Pipeline que ejecuta los scripts SQL de la carpeta `data/` o `sql/dml/` de forma ordenada.
    *   **`sql/`**: Directorio principal para los scripts SQL, organizados por su función (DDL, DML, Consultas).
        *   **`ddl/`**: (Data Definition Language) Scripts para definir la estructura de la base de datos.
            *   `01_create_database.sql`: Script para crear la base de datos (schema).
            *   `02_create_tables.sql`: Script para crear todas las tablas, vistas y otros objetos.
        *   **`dml/`**: (Data Manipulation Language) Scripts para la inserción y manipulación de datos. Contiene los mismos datos que la carpeta `scripts/data/` para una ejecución ordenada.
        *   **`queries/`**: Consultas SQL para realizar pruebas, validaciones y análisis.
            *   `complex_analytical_queries.sql`: Consultas complejas para análisis de datos y generación de reportes.
            *   `test_queries.sql`: Consultas simples para verificar que los datos se insertaron correctamente.