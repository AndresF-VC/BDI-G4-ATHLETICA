# trainings_fake.py
from fake_data_generic import FakeGenericTable
import argparse

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--records',     type=int,   required=True)
    parser.add_argument('--variability', type=float, default=0.3)
    parser.add_argument('--prefix',      type=str,   default="01")
    args = parser.parse_args()

    foreign_keys = {
        'athlete_id': 'athletes',
        'coach_id':   'coaches'
    }

    table = FakeGenericTable(
        table_name="trainings",
        schema_name="olympus",
        columns=['athlete_id', 'coach_id', 'date', 'duration_minutes', 'training_type'],
        faker_providers=['athlete_id', 'coach_id', 'date_this_year', 'random_int', 'word'],
        prefix=args.prefix,
        foreign_keys=foreign_keys
    )

    records = table.generate_fake_data(args.records, variability=args.variability)
    table.export_to_sql_file(records)
    table.export_foreign_keys_file(records, columns_export=list(foreign_keys.keys()))

if __name__ == "__main__":
    main()
