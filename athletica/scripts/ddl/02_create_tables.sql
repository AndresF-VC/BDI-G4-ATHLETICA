-- ##################################################
-- #              TABLE DEFINITIONS                 #
-- ##################################################

-- Independent tables
CREATE TABLE IF NOT EXISTS olympus.nationalities (
    nationality_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS olympus.categories (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    min_age INT,
    max_age INT
);

CREATE TABLE IF NOT EXISTS olympus.clubs (
    club_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    city VARCHAR(100),
    country VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS olympus.disciplines (
    discipline_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS olympus.events (
    event_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    date DATE,
    location VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS olympus.coaches (
    coach_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    specialty VARCHAR(100)
);

-- Dependent tables
CREATE TABLE IF NOT EXISTS olympus.athletes (
    athlete_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    birth_date DATE,
    gender VARCHAR(10) CHECK (gender IN ('Male', 'Female', 'Other')),
    nationality_id INT REFERENCES olympus.nationalities(nationality_id) ON UPDATE CASCADE ON DELETE SET NULL,
    category_id INT REFERENCES olympus.categories(category_id) ON UPDATE CASCADE ON DELETE SET NULL,
    club_id INT REFERENCES olympus.clubs(club_id) ON UPDATE CASCADE ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS olympus.participations (
    participation_id SERIAL PRIMARY KEY,
    athlete_id INT REFERENCES olympus.athletes(athlete_id) ON UPDATE CASCADE ON DELETE CASCADE,
    event_id INT REFERENCES olympus.events(event_id) ON UPDATE CASCADE ON DELETE CASCADE,
    discipline_id INT REFERENCES olympus.disciplines(discipline_id) ON UPDATE CASCADE ON DELETE CASCADE,
    result VARCHAR(100),
    position INT
);

CREATE TABLE IF NOT EXISTS olympus.trainings (
    training_id SERIAL PRIMARY KEY,
    athlete_id INT REFERENCES olympus.athletes(athlete_id) ON UPDATE CASCADE ON DELETE CASCADE,
    coach_id INT REFERENCES olympus.coaches(coach_id) ON UPDATE CASCADE ON DELETE CASCADE,
    date DATE,
    duration_minutes INT,
    training_type VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS olympus.injuries (
    injury_id SERIAL PRIMARY KEY,
    athlete_id INT REFERENCES olympus.athletes(athlete_id) ON UPDATE CASCADE ON DELETE CASCADE,
    description TEXT,
    date DATE,
    estimated_duration_days INT
);

CREATE TABLE IF NOT EXISTS olympus.medical_history (
    history_id SERIAL PRIMARY KEY,
    athlete_id INT REFERENCES olympus.athletes(athlete_id) ON UPDATE CASCADE ON DELETE CASCADE,
    date DATE,
    observations TEXT
);

CREATE TABLE IF NOT EXISTS olympus.users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50),
    athlete_id INT REFERENCES olympus.athletes(athlete_id) ON UPDATE CASCADE ON DELETE SET NULL,
    coach_id INT REFERENCES olympus.coaches(coach_id) ON UPDATE CASCADE ON DELETE SET NULL
);

-- ##################################################
-- #             INDEX DEFINITIONS                  #
-- ##################################################

CREATE INDEX idx_athletes_name ON olympus.athletes(name);
CREATE INDEX idx_events_date ON olympus.events(date);
CREATE INDEX idx_participations_position ON olympus.participations(position);
CREATE INDEX idx_trainings_date ON olympus.trainings(date);
CREATE INDEX idx_injuries_date ON olympus.injuries(date);
CREATE INDEX idx_medical_history_date ON olympus.medical_history(date);
CREATE INDEX idx_users_username ON olympus.users(username);

-- ##################################################
-- #               END DOCUMENTATION                #
-- ##################################################