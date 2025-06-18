-- 11-OLYMPUS-TRAININGS: añade sesiones de entrenamiento hasta 100 filas
INSERT INTO olympus.trainings (athlete_id, coach_id, date, duration_minutes, training_type)
SELECT
  a.athlete_id,
  (floor(random()*5)+1)::int,
  CURRENT_DATE - (floor(random()*60)) * INTERVAL '1 day',
  (floor(random()*75)+30)::int,
  (ARRAY[
    'Sprint drills','Endurance run','Gym strength','Flexibility',
    'Agility circuit','Interval training','Technical skills'
  ])[floor(random()*7+1)]
FROM generate_series(
  (SELECT COALESCE(MAX(training_id),0)+1 FROM olympus.trainings),
  100
) AS x(s)
CROSS JOIN LATERAL (
  SELECT athlete_id FROM olympus.athletes ORDER BY random() LIMIT 1
) AS a
WHERE (SELECT COUNT(*) FROM olympus.trainings) < 100;
