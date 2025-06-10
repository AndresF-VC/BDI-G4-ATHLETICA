# athletes_fake.py
from fake_data_generic import FakeGenericTable
import argparse

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--records',     type=int,   required=True)
    parser.add_argument('--variability', type=float, default=0.3)
    parser.add_argument('--prefix',      type=str,   default="01")
    args = parser.parse_args()

    foreign_keys = {
        'nationality_id': 'nationalities',
        'category_id':    'categories',
        'club_id':        'clubs'
    }

    table = FakeGenericTable(
        table_name="athletes",
        schema_name="olympus",
        columns=['name', 'birth_date', 'gender', 'nationality_id', 'category_id', 'club_id'],
        faker_providers=[
            'name',
            'date_of_birth',
            {'method': 'random_element', 'elements': ['Male', 'Female', 'Other']},
            'nationality_id',
            'category_id',
            'club_id'
        ],
        prefix=args.prefix,
        foreign_keys=foreign_keys
    )

    records = table.generate_fake_data(args.records, variability=args.variability)
    table.export_to_sql_file(records)
    table.export_foreign_keys_file(records, columns_export=list(foreign_keys.keys()))

if __name__ == "__main__":
    main()
