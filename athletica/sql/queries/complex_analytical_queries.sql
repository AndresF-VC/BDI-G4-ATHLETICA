-- ##################################################
-- #          10 COMPLEX ANALYTICAL QUERIES         #
-- ##################################################

-- Query 1: Athlete's Age at Time of Each Medal Win
-- Demonstrates: Multiple JOINs, Date/Time functions (AGE)
-- Purpose: To analyze the age at which athletes achieve peak performance (winning a medal).
------------------------------------------------------------------------------------------
SELECT
    a.name AS athlete_name,
    e.name AS event_name,
    d.name AS discipline,
    p.position,
    e.date AS event_date,
    a.birth_date,
    AGE(e.date, a.birth_date) AS age_at_event
FROM
    olympus.athletes a
JOIN
    olympus.participations p ON a.athlete_id = p.athlete_id
JOIN
    olympus.events e ON p.event_id = e.event_id
JOIN
    olympus.disciplines d ON p.discipline_id = d.discipline_id
WHERE
    p.position IN (1, 2, 3) -- Filter for medal positions
ORDER BY
    age_at_event DESC;


-- Query 2: Coach Effectiveness - Medal Count per Coached Athlete
-- Demonstrates: Multiple JOINs, Advanced Aggregation (COUNT, DISTINCT), Subquery in FROM clause (derived table)
-- Purpose: To identify which coaches are most effective at training athletes to win medals.
------------------------------------------------------------------------------------------
SELECT
    c.name AS coach_name,
    c.specialty,
    COUNT(p.participation_id) AS total_medals_won_by_their_athletes,
    COUNT(DISTINCT p.athlete_id) AS number_of_medal_winning_athletes
FROM
    olympus.coaches c
JOIN
    olympus.trainings t ON c.coach_id = t.coach_id
JOIN
    -- This join is on a unique combination of athlete and their medal-winning participations
    (SELECT DISTINCT athlete_id, participation_id
     FROM olympus.participations
     WHERE position <= 3) AS medal_participations p ON t.athlete_id = p.athlete_id
GROUP BY
    c.coach_id, c.name, c.specialty
ORDER BY
    total_medals_won_by_their_athletes DESC;


-- Query 3: Ranking Athletes Within Each Discipline Using a Window Function
-- Demonstrates: Window Functions (RANK), Common Table Expression (CTE), Multiple JOINs
-- Purpose: To rank athletes based on their best performance within each specific discipline.
------------------------------------------------------------------------------------------
WITH AthletePerformance AS (
    SELECT
        a.name AS athlete_name,
        d.name AS discipline_name,
        p.position,
        p.result,
        e.name as event_name,
        RANK() OVER(PARTITION BY d.discipline_id ORDER BY p.position ASC, p.result ASC) as rank_in_discipline
    FROM
        olympus.participations p
    JOIN
        olympus.athletes a ON p.athlete_id = a.athlete_id
    JOIN
        olympus.disciplines d ON p.discipline_id = d.discipline_id
    JOIN
        olympus.events e ON p.event_id = e.event_id
    WHERE
        p.position IS NOT NULL
)
SELECT
    *
FROM
    AthletePerformance
WHERE
    rank_in_discipline <= 3 -- Show top 3 ranks per discipline
ORDER BY
    discipline_name, rank_in_discipline;


-- Query 4: Find Each Athlete's Most Recent Participation (Correlated Subquery)
-- Demonstrates: Correlated Subquery
-- Purpose: To get a snapshot of the last time each athlete competed.
------------------------------------------------------------------------------------------
SELECT
    a.name as athlete_name,
    a.birth_date,
    (SELECT e.name
     FROM olympus.events e
     JOIN olympus.participations p ON e.event_id = p.event_id
     WHERE p.athlete_id = a.athlete_id
     ORDER BY e.date DESC
     LIMIT 1) AS last_event_participated,
    (SELECT e.date
     FROM olympus.events e
     JOIN olympus.participations p ON e.event_id = p.event_id
     WHERE p.athlete_id = a.athlete_id
     ORDER BY e.date DESC
     LIMIT 1) AS last_event_date
FROM
    olympus.athletes a
ORDER BY
    last_event_date DESC NULLS LAST;


-- Query 5: Athletes Who Competed Shortly After an Injury
-- Demonstrates: Multiple JOINs, Date/Time operations (INTERVAL)
-- Purpose: To identify athletes who might have returned to competition too quickly after an injury.
------------------------------------------------------------------------------------------
SELECT
    a.name AS athlete_name,
    i.description AS injury,
    i.date AS injury_date,
    e.name AS event_name,
    e.date AS competition_date,
    e.date - i.date AS days_between_injury_and_competition
FROM
    olympus.athletes a
JOIN
    olympus.injuries i ON a.athlete_id = i.athlete_id
JOIN
    olympus.participations p ON a.athlete_id = p.athlete_id
JOIN
    olympus.events e ON p.event_id = e.event_id
WHERE
    e.date > i.date -- The competition must be after the injury
    AND e.date <= (i.date + INTERVAL '30 day') -- And within 30 days of the injury
ORDER BY
    a.name, e.date;


-- Query 6: Nationalities Medal Leaderboard with a Points System
-- Demonstrates: Advanced Aggregation (SUM with CASE), Multiple JOINs, GROUP BY
-- Purpose: To create a leaderboard of countries based on a weighted medal count (Gold=3, Silver=2, Bronze=1).
------------------------------------------------------------------------------------------
SELECT
    n.name AS country,
    SUM(CASE WHEN p.position = 1 THEN 1 ELSE 0 END) AS gold_medals,
    SUM(CASE WHEN p.position = 2 THEN 1 ELSE 0 END) AS silver_medals,
    SUM(CASE WHEN p.position = 3 THEN 1 ELSE 0 END) AS bronze_medals,
    SUM(
        CASE
            WHEN p.position = 1 THEN 3 -- 3 points for Gold
            WHEN p.position = 2 THEN 2 -- 2 points for Silver
            WHEN p.position = 3 THEN 1 -- 1 point for Bronze
            ELSE 0
        END
    ) AS total_points
FROM
    olympus.nationalities n
JOIN
    olympus.athletes a ON n.nationality_id = a.nationality_id
JOIN
    olympus.participations p ON a.athlete_id = p.athlete_id
WHERE
    p.position IN (1, 2, 3)
GROUP BY
    n.name
ORDER BY
    total_points DESC, gold_medals DESC;


-- Query 7: Athletes Who Performed Better Than Their Own Average (Correlated Subquery)
-- Demonstrates: Correlated Subquery in WHERE clause, Self-Join concept
-- Purpose: To find standout performances where an athlete significantly beat their personal average position in a discipline.
------------------------------------------------------------------------------------------
SELECT
    a.name AS athlete_name,
    d.name AS discipline,
    e.name AS event_name,
    p1.position AS standout_position
FROM
    olympus.participations p1
JOIN
    olympus.athletes a ON p1.athlete_id = a.athlete_id
JOIN
    olympus.disciplines d ON p1.discipline_id = d.discipline_id
JOIN
    olympus.events e ON p1.event_id = e.event_id
WHERE
    p1.position < (
        -- Correlated subquery calculates the average position for THIS athlete in THIS discipline
        SELECT AVG(p2.position)
        FROM olympus.participations p2
        WHERE p2.athlete_id = p1.athlete_id
          AND p2.discipline_id = p1.discipline_id
    )
ORDER BY
    a.name, d.name;


-- Query 8: Coaches with Multiple Medal-Winning Athletes in a Single Year
-- Demonstrates: Multiple JOINs, GROUP BY, HAVING clause with complex condition
-- Purpose: To identify coaches who have a broad impact, successfully training more than one top athlete simultaneously.
------------------------------------------------------------------------------------------
SELECT
    c.name AS coach_name,
    EXTRACT(YEAR FROM e.date) AS season_year,
    COUNT(DISTINCT a.athlete_id) AS number_of_medal_winners
FROM
    olympus.coaches c
JOIN
    olympus.trainings tr ON c.coach_id = tr.coach_id
JOIN
    olympus.athletes a ON tr.athlete_id = a.athlete_id
JOIN
    olympus.participations p ON a.athlete_id = p.athlete_id
JOIN
    olympus.events e ON p.event_id = e.event_id
WHERE
    p.position <= 3
GROUP BY
    c.name, season_year
HAVING
    COUNT(DISTINCT a.athlete_id) > 1 -- The coach must have trained MORE THAN ONE distinct medal-winning athlete
ORDER BY
    season_year DESC, number_of_medal_winners DESC;


-- Query 9: Longest Time Gap Between Competitions for Each Athlete
-- Demonstrates: Window Functions (LAG), CTE, Date/Time arithmetic
-- Purpose: To identify athletes who have had long breaks in their careers, which could indicate a major injury or time off.
------------------------------------------------------------------------------------------
WITH EventGaps AS (
    SELECT
        a.name AS athlete_name,
        e.date AS current_event_date,
        LAG(e.date, 1) OVER (PARTITION BY a.athlete_id ORDER BY e.date) AS previous_event_date
    FROM
        olympus.athletes a
    JOIN
        olympus.participations p ON a.athlete_id = p.athlete_id
    JOIN
        olympus.events e ON p.event_id = e.event_id
)
SELECT
    athlete_name,
    MAX(current_event_date - previous_event_date) AS longest_gap_in_days
FROM
    EventGaps
WHERE
    previous_event_date IS NOT NULL
GROUP BY
    athlete_name
HAVING
    MAX(current_event_date - previous_event_date) IS NOT NULL
ORDER BY
    longest_gap_in_days DESC;


-- Query 10: Comprehensive Athlete Profile with CTEs
-- Demonstrates: Multiple CTEs, LEFT JOINs for completeness, Multiple aggregations
-- Purpose: To generate a full summary report for a single athlete, combining personal data, performance stats, and training summaries.
------------------------------------------------------------------------------------------
WITH PerformanceSummary AS (
    SELECT
        athlete_id,
        COUNT(*) AS total_participations,
        AVG(position) AS avg_position,
        SUM(CASE WHEN position = 1 THEN 1 ELSE 0 END) AS gold_medals
    FROM olympus.participations
    GROUP BY athlete_id
),
TrainingSummary AS (
    SELECT
        athlete_id,
        SUM(duration_minutes) AS total_training_minutes,
        COUNT(DISTINCT coach_id) AS number_of_coaches
    FROM olympus.trainings
    GROUP BY athlete_id
),
InjuryReport AS (
    SELECT
        athlete_id,
        COUNT(*) AS number_of_injuries,
        MAX(date) AS last_injury_date
    FROM olympus.injuries
    GROUP BY athlete_id
)
SELECT
    a.name,
    a.gender,
    nat.name AS nationality,
    cl.name AS club,
    perf.total_participations,
    ROUND(perf.avg_position, 2) AS average_position,
    perf.gold_medals,
    tr.total_training_minutes,
    ir.number_of_injuries,
    ir.last_injury_date
FROM
    olympus.athletes a
LEFT JOIN
    olympus.nationalities nat ON a.nationality_id = nat.nationality_id
LEFT JOIN
    olympus.clubs cl ON a.club_id = cl.club_id
LEFT JOIN
    PerformanceSummary perf ON a.athlete_id = perf.athlete_id
LEFT JOIN
    TrainingSummary tr ON a.athlete_id = tr.athlete_id
LEFT JOIN
    InjuryReport ir ON a.athlete_id = ir.athlete_id
ORDER BY
    a.name;