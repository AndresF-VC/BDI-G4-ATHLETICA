#!/usr/bin/env python3
import argparse
import math
import random
import os
from datetime import datetime
from typing import Dict, List, Any, Optional, Union, Callable

from faker import Faker

# Added for direct DB insertion
import psycopg2
from psycopg2 import sql

class FakeGenericTable:
    """
    Generic table generator that accepts column definitions, faker providers, and schema.
    Supports exporting to SQL files or inserting directly into PostgreSQL.
    """
    AVAILABLE_LOCALES = [
        'en_US', 'en_GB', 'es_ES', 'es_MX', 'fr_FR', 'de_DE', 'it_IT', 'pt_BR', 'nl_NL'
    ]

    def __init__(
        self,
        table_name: str,
        schema_name: str,
        columns: List[str],
        faker_providers: List[Union[str, Dict, Callable]],
        prefix: str = None,
        path_output: str = None,
        foreign_keys: Optional[Dict[str, List[Any]]] = None,
        db_conn_str: Optional[str] = None,
    ):
        self.table_name = table_name
        self.schema_name = schema_name
        self.columns = columns
        self.faker_providers = faker_providers
        self.foreign_keys = foreign_keys or {}
        self.prefix = prefix
        self.db_conn_str = db_conn_str or os.getenv('DATABASE_URL')
        self.path_output = self._resolve_output_path(path_output)

        if len(columns) != len(faker_providers):
            raise ValueError(
                f"Columns count ({len(columns)}) does not match providers count ({len(faker_providers)})"
            )

    def _resolve_output_path(self, path_output: str = None) -> str:
        default_path = (
            os.path.abspath(path_output)
            if path_output
            else os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'data'))
        )
        os.makedirs(default_path, exist_ok=True)
        return default_path

    def get_full_table_name(self) -> str:
        return f"{self.schema_name}.{self.table_name}"

    def _select_locales(self, variability: float) -> List[str]:
        if variability <= 0:
            return [self.AVAILABLE_LOCALES[0]]
        num = max(1, min(math.ceil(variability * len(self.AVAILABLE_LOCALES)), len(self.AVAILABLE_LOCALES)))
        return random.sample(self.AVAILABLE_LOCALES, num)

    def _get_faker_for_locale(self, locale: str) -> Faker:
        return Faker(locale)

    def _get_data_for_column(
        self, faker: Faker, column: str, provider_info: Union[str, Dict, Callable]
    ) -> Any:
        if column in self.foreign_keys:
            return random.choice(self.foreign_keys[column])

        if isinstance(provider_info, str):
            if not hasattr(faker, provider_info):
                raise ValueError(f"Unknown Faker provider: {provider_info}")
            return getattr(faker, provider_info)()

        if isinstance(provider_info, dict):
            method = provider_info.get('method')
            params = {k: v for k, v in provider_info.items() if k != 'method'}
            if not hasattr(faker, method):
                raise ValueError(f"Unknown provider method: {method}")
            return getattr(faker, method)(**params)

        if callable(provider_info):
            return provider_info(faker)

        raise ValueError(f"Unsupported provider type for {column}")

    def generate_fake_data(
        self,
        num_records: int,
        seed: int = 42,
        variability: float = 0.3,
    ) -> List[Dict[str, Any]]:
        random.seed(seed)
        Faker.seed(seed)
        locales = self._select_locales(variability)
        fakers = [self._get_faker_for_locale(loc) for loc in locales]

        records = []
        for _ in range(num_records):
            faker = random.choice(fakers)
            rec = {col: self._get_data_for_column(faker, col, prov)
                   for col, prov in zip(self.columns, self.faker_providers)}
            records.append(rec)
        return records

    def _format_value_for_sql(self, value: Any) -> str:
        if value is None:
            return 'NULL'
        if isinstance(value, bool):
            return str(int(value))
        if isinstance(value, (int, float)):
            return str(value)
        if isinstance(value, datetime):
            return f"'{value.strftime('%Y-%m-%d %H:%M:%S')}'"
        # Escape single quotes
        return f"'{str(value).replace("'", "''")}'"

    def to_sql(self, records: List[Dict[str, Any]]) -> str:
        if not records:
            return ''
        cols = records[0].keys()
        col_str = ', '.join(cols)
        full_table = self.get_full_table_name()
        stmts = []
        batch_size = 10000
        for i in range(0, len(records), batch_size):
            batch = records[i:i+batch_size]
            vals = [
                '(' + ', '.join(self._format_value_for_sql(rec[c]) for c in cols) + ')'
                for rec in batch
            ]
            stmts.append(f"INSERT INTO {full_table} ({col_str}) VALUES " + ','.join(vals) + ';')
        return '\n'.join(stmts)

    def export_to_sql_file(self, records: List[Dict[str, Any]]) -> None:
        filename = os.path.join(
            self.path_output,
            f"{self.prefix}-{self.schema_name.upper()}-{self.table_name.upper()}.sql"
        )
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(self.to_sql(records))
        print(f"Exported {len(records)} to SQL file: {filename}")

    def insert_into_db(self, records: List[Dict[str, Any]]) -> None:
        """
        Insert records directly into PostgreSQL table using psycopg2.
        """
        if not self.db_conn_str:
            raise ValueError('No database connection string provided')

        conn = psycopg2.connect(self.db_conn_str)
        cur = conn.cursor()
        full_table = sql.Identifier(self.schema_name), sql.Identifier(self.table_name)
        cols = records[0].keys()
        col_identifiers = [sql.Identifier(c) for c in cols]

        # Build INSERT statement
        insert_sql = sql.SQL('INSERT INTO {}.{} ({}) VALUES %s').format(
            sql.Identifier(self.schema_name), sql.Identifier(self.table_name),
            sql.SQL(',').join(col_identifiers)
        )
        # Prepare data
        values_list = [[rec[c] for c in cols] for rec in records]
        # Use execute_values for batch insert
        from psycopg2.extras import execute_values
        execute_values(cur, insert_sql, values_list)
        conn.commit()
        cur.close()
        conn.close()
        print(f"Inserted {len(records)} rows into {self.schema_name}.{self.table_name}")


def main():
    parser = argparse.ArgumentParser(description='Generate and load fake data')
    parser.add_argument('--table', required=True, help='Table name')
    parser.add_argument('--schema', required=True, help='Schema name')
    parser.add_argument('--columns', required=True,
                        help='Comma-separated column names')
    parser.add_argument('--providers', required=True,
                        help='JSON array or comma-separated list of providers')
    parser.add_argument('--records', type=int, required=True, help='Num records')
    parser.add_argument('--prefix', default='01', help='SQL file prefix')
    parser.add_argument('--path-output', default=None, help='Output directory')
    parser.add_argument('--db-url', default=None,
                        help='PostgreSQL connection URL (overrides env DATABASE_URL)')
    parser.add_argument('--variability', type=float, default=0.3)
    parser.add_argument('--seed', type=int, default=42)
    args = parser.parse_args()

    # Parse columns and providers
    cols = [c.strip() for c in args.columns.split(',')]
    try:
        provs = eval(args.providers)
    except Exception:
        provs = [p.strip() for p in args.providers.split(',')]

    table = FakeGenericTable(
        table_name=args.table,
        schema_name=args.schema,
        columns=cols,
        faker_providers=provs,
        prefix=args.prefix,
        path_output=args.path_output,
        db_conn_str=args.db_url or os.getenv('DATABASE_URL'),
    )

    recs = table.generate_fake_data(
        num_records=args.records,
        seed=args.seed,
        variability=args.variability
    )

    if args.db_url or os.getenv('DATABASE_URL'):
        table.insert_into_db(recs)
    else:
        table.export_to_sql_file(recs)

if __name__ == '__main__':
    main()
