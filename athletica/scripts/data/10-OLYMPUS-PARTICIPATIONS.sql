-- 10-OLYMPUS-PARTICIPATIONS.sql
INSERT INTO olympus.participations (athlete_id, event_id, discipline_id, result, position)
SELECT
  
  athlete_ids[floor(random()*array_length(athlete_ids,1)) + 1]          AS athlete_id,
  
  (floor(random()*8)+1)::int                                           AS event_id,
  (floor(random()*8)+1)::int                                           AS discipline_id,
  
  CASE
    WHEN random() < 0.5
    THEN to_char((random()*20+9)::numeric, 'FM9.99') || 's'
    ELSE to_char(
           ((floor(random()*3)+1)*60                                  
            + floor(random()*60) ) * INTERVAL '1 second',            
           'MI:SS'
         )
  END                                                                   AS result,
  
  (floor(random()*50)+1)::int                                           AS position
FROM (
   SELECT array_agg(athlete_id) AS athlete_ids
     FROM olympus.athletes
) AS a
CROSS JOIN generate_series(1,100) AS s(n);