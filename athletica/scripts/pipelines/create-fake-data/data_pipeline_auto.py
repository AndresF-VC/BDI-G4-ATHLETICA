# data_pipeline_auto.py
#!/usr/bin/env python3
import os
import argparse
import logging
import subprocess
from concurrent.futures import ProcessPoolExecutor, as_completed
from tqdm import tqdm

# Lista de scripts en orden de dependencias
SCRIPT_LIST = [
    'nationalities_fake.py',
    'categories_fake.py',
    'clubs_fake.py',
    'disciplines_fake.py',
    'events_fake.py',
    'coaches_fake.py',
    'athletes_fake.py',
    'injuries_fake.py',
    'medical_history_fake.py',
    'participations_fake.py',
    'trainings_fake.py',
    'users_fake.py',
]

def setup_logging():
    logging.basicConfig(
        format='%(asctime)s %(levelname)s: %(message)s',
        level=logging.INFO,
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    return logging.getLogger()

def run_script(script_path, records, variability, prefix):
    cmd = [
        'python3', script_path,
        '--records', str(records),
        '--variability', str(variability),
        '--prefix', prefix
    ]
    result = subprocess.run(cmd, check=True, cwd=os.path.dirname(script_path))
    return result

def execute_population_scripts(script_paths, records, variability, prefix, parallel=False):
    logger = logging.getLogger()
    # Validar existencia de cada script
    missing = [p for p in script_paths if not os.path.isfile(p)]
    if missing:
        logger.error(f"No se encontraron los siguientes scripts: {missing}")
        raise FileNotFoundError(f"Scripts faltantes: {missing}")

    if parallel:
        max_workers = min(len(script_paths), os.cpu_count() or 1)
        with ProcessPoolExecutor(max_workers=max_workers) as executor:
            futures = {
                executor.submit(run_script, p, records, variability, prefix): p
                for p in script_paths
            }
            for fut in tqdm(as_completed(futures), total=len(futures), desc="Ejecutando scripts"):
                script = futures[fut]
                try:
                    fut.result()
                    logger.info(f"✔ {script}")
                except Exception as e:
                    logger.error(f"✖ Error en {script}: {e}")
    else:
        for script in tqdm(script_paths, desc="Ejecutando scripts"):
            try:
                run_script(script, records, variability, prefix)
                logger.info(f"✔ {script}")
            except subprocess.CalledProcessError as e:
                logger.error(f"✖ {script} falló (exit {e.returncode})")
                raise

def main():
    parser = argparse.ArgumentParser(
        description="Orquestador para poblar la base de datos Olympic"
    )
    parser.add_argument('--scripts-dir',  type=str, default='.', help='Directorio donde están los scripts')
    parser.add_argument('--records',      type=int, default=50, help='Nº de registros por script')
    parser.add_argument('--variability',  type=float, default=0.3, help='Variabilidad de Faker (0–1)')
    parser.add_argument('--prefix',       type=str, default='01', help='Prefijo para archivos SQL')
    parser.add_argument('--parallel',     action='store_true', help='Ejecutar en paralelo')
    args = parser.parse_args()

    logger = setup_logging()
    script_paths = [os.path.join(args.scripts_dir, s) for s in SCRIPT_LIST]

    try:
        execute_population_scripts(
            script_paths,
            records=args.records,
            variability=args.variability,
            prefix=args.prefix,
            parallel=args.parallel
        )
    except Exception as e:
        logger.error("Orquestador abortado por error", exc_info=True)
        exit(1)

if __name__ == "__main__":
    main()
