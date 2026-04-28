-- BigQuery Standard SQL
-- Median peak demand event duration (exact)

WITH peak_hours AS (
  SELECT interval_start_dt
  FROM `miso-load-analysis.miso.v_actual_load_system`
  WHERE system_load_mw >= 110423
),

tagged AS (
  SELECT
    interval_start_dt,
    LAG(interval_start_dt) OVER (ORDER BY interval_start_dt) AS prev_dt
  FROM peak_hours
),

flagged AS (
  SELECT
    interval_start_dt,
    CASE
      WHEN prev_dt IS NULL THEN 1
      WHEN DATETIME_DIFF(interval_start_dt, prev_dt, HOUR) = 1 THEN 0
      ELSE 1
    END AS is_new_event
  FROM tagged
),

events AS (
  SELECT
    interval_start_dt,
    SUM(is_new_event) OVER (ORDER BY interval_start_dt) AS event_id
  FROM flagged
),

event_durations AS (
  SELECT
    event_id,
    COUNT(*) AS event_hours
  FROM events
  GROUP BY event_id
),

ordered AS (
  SELECT
    event_hours,
    ROW_NUMBER() OVER (ORDER BY event_hours) AS rn,
    COUNT(*) OVER () AS n
  FROM event_durations
)

SELECT
  AVG(event_hours) AS median_event_duration_hours
FROM ordered
WHERE rn IN (DIV(n + 1, 2), DIV(n + 2, 2));
