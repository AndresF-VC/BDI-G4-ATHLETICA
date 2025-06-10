# coaches_fake.py
from fake_data_generic import FakeGenericTable
import argparse

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--records',     type=int,   required=True)
    parser.add_argument('--variability', type=float, default=0.3)
    parser.add_argument('--prefix',      type=str,   default="01")
    args = parser.parse_args()

    foreign_keys = {}

    table = FakeGenericTable(
        table_name="coaches",
        schema_name="olympus",
        columns=['name', 'specialty'],
        faker_providers=['name', 'job'],
        prefix=args.prefix,
        foreign_keys=foreign_keys
    )

    records = table.generate_fake_data(args.records, variability=args.variability)
    table.export_to_sql_file(records)
    # No hay FKs, así que export_foreign_keys_file no se usará

if __name__ == "__main__":
    main()
