-- =============================================================================
-- 07-OLYMPUS-ATHLETES.sql
--
-- Objetivo: Poblar la tabla de atletas con datos aleatorios para la fecha de
-- nacimiento, género y relaciones, tal como lo hace el script de Python.
-- Usamos cada nombre de la lista de atletas exactamente una vez.
-- =============================================================================
INSERT INTO olympus.athletes (name, birth_date, gender, nationality_id, category_id, club_id)
SELECT
    name,
    -- Genera una fecha de nacimiento aleatoria entre 1960 y 2009
    make_date(
        (1960 + floor(random() * 50))::int,
        (1 + floor(random() * 12))::int,
        (1 + floor(random() * 28))::int
    ) as birth_date,
    -- Elige un género aleatorio de la lista
    (ARRAY['Male', 'Female', 'Other'])[floor(random() * 3) + 1] as gender,
    -- Asigna una nacionalidad, categoría y club aleatorios
    (floor(random() * (SELECT COUNT(*) FROM olympus.nationalities)) + 1)::int,
    (floor(random() * (SELECT COUNT(*) FROM olympus.categories)) + 1)::int,
    (floor(random() * (SELECT COUNT(*) FROM olympus.clubs)) + 1)::int
FROM (
    VALUES
    ('Andrew Torres'), ('Michael Gomez'), ('Jorge Heath'), ('Daniel Brewer'), ('Christina Mueller'), ('Joseph Montoya'), ('Kevin Villa'), ('Morgan Wagner'),
    ('Robert Dyer DVM'), ('Jeffrey Hahn'), ('Linda Sanders'), ('Marissa Jones'), ('Cameron Alexander'), ('Michael Riddle'), ('Cory Donovan'), ('James Horn'),
    ('Natalie Marsh DDS'), ('Latoya Vaughn'), ('John Nolan'), ('Alicia Wilson'), ('Rebecca Perry'), ('Sandra Taylor'), ('Kimberly Ford'), ('Cassandra Hicks'),
    ('Cheryl Case'), ('Ashley Jones'), ('Michele Gonzalez'), ('Beth Hogan'), ('Daniel Barajas'), ('Monica Michael'), ('Kimberly Wu'), ('Kelly Wright'),
    ('Sabrina Wright'), ('Debra Ross'), ('April Melendez'), ('Ronald Delgado'), ('Dustin Beard'), ('Shannon Anderson'), ('Megan Miller'), ('Ronald Jones'),
    ('Cristina Kelly'), ('James West MD'), ('Stephen Butler'), ('Richard Lee'), ('Ryan Best'), ('Lisa Austin'), ('Elizabeth Frost'), ('Joseph Watson'),
    ('Melissa Morris'), ('Jose Cordova'), ('Leslie Smith'), ('Amanda Thomas'), ('Michael Ellis'), ('Ariana Liu'), ('Sandra Carter'), ('Kelly Conley'),
    ('Joseph Mason'), ('Brendan Hernandez'), ('Gary Fernandez'), ('Robert Adams'), ('Jerry Moore'), ('Krystal Blair'), ('Adam Sanchez'), ('Bridget Perkins'),
    ('Joseph Thomas'), ('Jessica Miles'), ('Douglas Chen'), ('Beth Austin'), ('Joseph Smith'), ('Michael Daniels'), ('William Morgan'), ('Renee Wheeler'),
    ('Luis Smith'), ('Jamie Williams'), ('Lindsey Hill'), ('Christina Todd'), ('Debra Ortiz'), ('Kelly Hamilton'), ('Cristina Smith'), ('Clinton Vargas'),
    ('Kimberly Hicks'), ('John Fleming'), ('Jeremy Powell'), ('Stephanie Santiago'), ('Joel Rios'), ('Brian Clark'), ('Jason Parsons'), ('Amy Shannon'),
    ('Aaron Henderson'), ('Kenneth Smith'), ('Jill Ramirez'), ('Jason Mitchell'), ('Jonathan Schmitt'), ('Christopher Allen'), ('Christopher Gilbert'),
    ('Miss Patricia Smith'), ('Tyler Greene'), ('Tanya Edwards'), ('Andrew Hughes'), ('Terry Austin')
) AS athletes_data(name);