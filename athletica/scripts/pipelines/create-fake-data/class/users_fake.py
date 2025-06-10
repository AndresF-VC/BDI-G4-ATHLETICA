# users_fake.py
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
        table_name="users",
        schema_name="olympus",
        columns=['username', 'password', 'role', 'athlete_id', 'coach_id'],
        faker_providers=[
            'user_name',
            'password',
            {'method': 'random_element', 'elements': ['admin', 'coach', 'athlete']},
            'athlete_id',
            'coach_id'
        ],
        prefix=args.prefix,
        foreign_keys=foreign_keys
    )

    records = table.generate_fake_data(args.records, variability=args.variability)
    table.export_to_sql_file(records)
    table.export_foreign_keys_file(records, columns_export=list(foreign_keys.keys()))

if __name__ == "__main__":
    main()
