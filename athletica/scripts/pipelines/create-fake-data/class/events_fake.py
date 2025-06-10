# events_fake.py
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
        table_name="events",
        schema_name="olympus",
        columns=['name', 'date', 'location'],
        faker_providers=['catch_phrase', 'date_this_decade', 'city'],
        prefix=args.prefix,
        foreign_keys=foreign_keys
    )

    records = table.generate_fake_data(args.records, variability=args.variability)
    table.export_to_sql_file(records)

if __name__ == "__main__":
    main()
