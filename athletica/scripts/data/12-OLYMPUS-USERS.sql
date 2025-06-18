-- =============================================================================
-- 12-OLYMPUS-USERS.sql
--
-- Objetivo: Poblar la tabla de usuarios. Replica la lógica del script de Python:
-- 1. Crea usuarios con su rol.
-- 2. Asigna un atleta ÚNICO a cada usuario de rol 'athlete'.
-- 3. Asigna un entrenador aleatorio a cada usuario de rol 'coach'.
-- 4. Usa una contraseña fija 'password123' para todos, como en el script.
-- =============================================================================
WITH users_data AS (
    SELECT
        username,
        role,
        -- Asignamos un número de fila a cada usuario para poder hacer un join único
        row_number() OVER() as rn
    FROM (
        VALUES
        ('johnsonjoshua', 'athlete'), ('thomas26', 'athlete'), ('crescencia31', 'athlete'), ('fernandosevilla', 'athlete'),
        ('qcocci', 'coach'), ('dwright', 'athlete'), ('natalia93', 'admin'), ('wbohnbach', 'admin'),
        ('christophemaillot', 'admin'), ('mjesus', 'coach'), ('rogerpinto', 'coach'), ('robinsonarthur', 'athlete'),
        ('brianromero', 'admin'), ('tygo51', 'athlete'), ('gracia12', 'admin'), ('maria-manuela24', 'athlete'),
        ('griseldacalderon', 'athlete'), ('de-haasnora', 'athlete'), ('antoine14', 'coach'), ('chartiervincent', 'athlete'),
        ('stoffelszmaurits', 'athlete'), ('helmuth32', 'athlete'), ('jbenigni', 'admin'), ('maria-dolores87', 'coach'),
        ('martinemily', 'admin'), ('amanda70', 'coach'), ('nverbruggen', 'admin'), ('gilbertreynaud', 'admin'),
        ('claudiomanzoni', 'coach'), ('liviatrentin', 'admin'), ('ljunk', 'coach'), ('siempeterse', 'coach'),
        ('guilherme34', 'admin'), ('herrmannthekla', 'coach'), ('ljordan', 'admin'), ('kevintrapp', 'athlete'),
        ('scott74', 'coach'), ('llettiere', 'coach'), ('brandon16', 'admin'), ('milovan-der-zijl', 'coach'),
        ('selinavan-de-pavert', 'coach'), ('usantoro', 'athlete'), ('noortje17', 'athlete'), ('williamsonjimmy', 'athlete'),
        ('kescolano', 'coach'), ('felicia64', 'admin'), ('matthieu39', 'admin'), ('robin74', 'admin'),
        ('rzijlmans', 'admin'), ('arcosmarco', 'coach'), ('paganinigian', 'admin'), ('lillyrosemann', 'admin'),
        ('odescalchimonica', 'coach'), ('araujomaria-luiza', 'athlete'), ('ycabezas', 'admin'), ('clementeric', 'admin'),
        ('ermannosonnino', 'coach'), ('escuderoruth', 'admin'), ('daviesabdul', 'coach'), ('maria-fernandacervantes', 'coach'),
        ('tallen', 'athlete'), ('ross52', 'athlete'), ('omoraleda', 'coach'), ('salgaripaloma', 'coach'),
        ('sina46', 'athlete'), ('mauriziomastroianni', 'admin'), ('kyle35', 'admin'), ('rfonseca', 'athlete'),
        ('mcastro', 'coach'), ('richard60', 'admin'), ('da-cunhapedro', 'athlete'), ('kellysmith', 'athlete'),
        ('palaumodesta', 'coach'), ('caiovieira', 'coach'), ('flavio77', 'coach'), ('acostarhonda', 'admin'),
        ('michael90', 'coach'), ('geraldine73', 'athlete'), ('nadiapardo', 'admin'), ('lucianoborgia', 'coach'),
        ('emanuel43', 'athlete'), ('larapinto', 'admin'), ('ninthe55', 'admin'), ('dmoraes', 'coach'),
        ('sofialamas', 'coach'), ('nicole52', 'athlete'), ('corinne88', 'admin'), ('rcomisso', 'athlete'),
        ('whitney78', 'coach'), ('ybailey', 'coach'), ('derrick99', 'coach'), ('mitchell01', 'athlete'),
        ('danielroland', 'admin'), ('glaunay', 'athlete'), ('davirios', 'coach'), ('zvan-der-loo', 'admin'),
        ('melissa71', 'athlete'), ('williamsmelvin', 'admin'), ('diego28', 'admin'), ('xbonneau', 'admin')
    ) AS u(username, role)
),
athletes_numbered AS (
    -- Asignamos un número de fila a cada atleta para poder asignarlo de forma única
    SELECT id as athlete_id, row_number() OVER (ORDER BY id) as rn
    FROM olympus.athletes
)
INSERT INTO olympus.users (username, email, password, role, athlete_id, coach_id)
SELECT
    ud.username,
    ud.username || '@athletica.com', -- Generar email
    'password123', -- Contraseña fija
    ud.role,
    CASE
        WHEN ud.role = 'athlete' THEN an.athlete_id
        ELSE NULL
    END as athlete_id,
    CASE
        WHEN ud.role = 'coach' THEN (SELECT id FROM olympus.coaches ORDER BY random() LIMIT 1)
        ELSE NULL
    END as coach_id
FROM users_data ud
-- Unimos usuarios de tipo atleta con un atleta único
LEFT JOIN athletes_numbered an ON ud.role = 'athlete' AND an.rn = (
    SELECT count(*)
    FROM users_data
    WHERE role = 'athlete' AND rn <= ud.rn
);