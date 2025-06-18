-- ##################################################
-- #             TEST QUERIES (DQL)                 #
-- ##################################################

-- 01. Basic Queries (single table)
---------------------------------------------------

-- List all athletes
SELECT * FROM olympus.athletes;

-- List all events scheduled for 2024
SELECT name, date, location FROM olympus.events WHERE EXTRACT(YEAR FROM date) = 2024;

-- Find all coaches specializing in 'Swimming'
SELECT name, specialty FROM olympus.coaches WHERE specialty ILIKE '%Swimming%';


-- 02. Queries with JOINs (linking tables)
---------------------------------------------------

-- List athletes with their club name and nationality
SELECT
    a.name AS athlete_name,
    a.gender,
    cl.name AS club_name,
    n.name AS nationality
FROM
    olympus.athletes a
JOIN olympus.clubs cl ON a.club_id = cl.club_id
JOIN olympus.nationalities n ON a.nationality_id = n.nationality_id;

-- Show all participations with athlete, event, and discipline names
SELECT
    ath.name AS athlete_name,
    ev.name AS event_name,
    d.name AS discipline_name,
    p.result,
    p.position
FROM
    olympus.participations p
JOIN olympus.athletes ath ON p.athlete_id = ath.athlete_id
JOIN olympus.events ev ON p.event_id = ev.event_id
JOIN olympus.disciplines d ON p.discipline_id = d.discipline_id
ORDER BY
    ev.date DESC;

-- List which coach trains which athlete
SELECT
    c.name AS coach_name,
    c.specialty,
    a.name AS athlete_name
FROM
    olympus.trainings t
JOIN olympus.coaches c ON t.coach_id = c.coach_id
JOIN olympus.athletes a ON t.athlete_id = a.athlete_id;


-- 03. Queries with aggregation and filtering
---------------------------------------------------

-- Count how many athletes are in each club
SELECT
    cl.name AS club_name,
    COUNT(a.athlete_id) AS number_of_athletes
FROM
    olympus.athletes a
JOIN olympus.clubs cl ON a.club_id = cl.club_id
GROUP BY
    cl.name
ORDER BY
    number_of_athletes DESC;

-- Find athletes who have won medals (position 1, 2, or 3) in any event
SELECT
    ath.name AS athlete_name,
    ev.name AS event_name,
    p.position,
    p.result
FROM
    olympus.participations p
JOIN olympus.athletes ath ON p.athlete_id = ath.athlete_id
JOIN olympus.events ev ON p.event_id = ev.event_id
WHERE
    p.position IN (1, 2, 3)
ORDER BY
    p.position ASC;

-- Calculate the total training duration for each athlete
SELECT
    a.name AS athlete_name,
    SUM(t.duration_minutes) AS total_training_minutes,
    (SUM(t.duration_minutes) / 60) AS total_training_hours
FROM
    olympus.trainings t
JOIN olympus.athletes a ON t.athlete_id = a.athlete_id
GROUP BY
    a.name
ORDER BY
    total_training_minutes DESC;


-- 04. Complex Queries
---------------------------------------------------

-- List all Colombian athletes and their medals (positions 1 to 3)
SELECT
    a.name AS athlete_name,
    e.name AS event_name,
    d.name AS discipline_name,
    p.position
FROM
    olympus.participations p
JOIN olympus.athletes a ON p.athlete_id = a.athlete_id
JOIN olympus.nationalities n ON a.nationality_id = n.nationality_id
JOIN olympus.events e ON p.event_id = e.event_id
JOIN olympus.disciplines d ON p.discipline_id = d.discipline_id
WHERE
    n.name = 'Colombian' AND p.position <= 3;

-- Find athletes with a registered injury and view their complete medical history
SELECT
    a.name AS athlete_name,
    i.description AS injury_description,
    i.date AS injury_date,
    mh.date AS medical_history_date,
    mh.observations AS medical_observations
FROM
    olympus.athletes a
JOIN olympus.injuries i ON a.athlete_id = i.athlete_id
LEFT JOIN olympus.medical_history mh ON a.athlete_id = mh.athlete_id
ORDER BY
    a.name, mh.date DESC;

-- Show athletes who have NOT participated in any event yet (using LEFT JOIN)
-- (To test this query, you can add a new athlete without any participations)
-- INSERT INTO olympus.athletes (name, birth_date, gender, nationality_id, category_id, club_id) VALUES ('New Athlete', '2003-03-03', 'Other', 1, 2, 1);
SELECT
    a.name AS athlete_name,
    a.birth_date
FROM
    olympus.athletes a
LEFT JOIN olympus.participations p ON a.athlete_id = p.athlete_id
WHERE
    p.participation_id IS NULL;