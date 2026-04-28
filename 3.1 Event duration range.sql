-- BigQuery Standard SQL
-- Event duration (exact hours) and number of events

WITH peak_hours AS (
  SELECT
    interval_start_dt
  FROM `miso-load-analysis.miso.v_actual_load_system`
  WHERE system_load_mw >= 110423
),

tagged AS (
  SELECT
    interval_start_dt,
    LAG(interval_start_dt) OVER (ORDER BY interval_start_dt) AS prev_dt
  FROM peak_hours
),

events AS (
  SELECT
    interval_start_dt,
    SUM(
      CASE
        WHEN prev_dt IS NULL THEN 1
        WHEN DATETIME_DIFF(interval_start_dt, prev_dt, HOUR) = 1 THEN 0
        ELSE 1
      END
    ) OVER (ORDER BY interval_start_dt) AS event_id
  FROM tagged
),

event_durations AS (
  SELECT
    event_id,
    COUNT(*) AS event_hours
  FROM events
  GROUP BY event_id
)

SELECT
  event_hours,
  COUNT(*) AS num_events
FROM event_durations
GROUP BY event_hours
ORDER BY event_hours;
