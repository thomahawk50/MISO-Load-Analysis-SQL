-- BigQuery Standard SQL
-- Peak demand event duration buckets (share of events)
-- Buckets: 1–2, 3–4, 5–6, 7–8, 9–10 hours

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
)

SELECT
  CASE
    WHEN event_hours BETWEEN 1 AND 2 THEN '1–2 hours'
    WHEN event_hours BETWEEN 3 AND 4 THEN '3–4 hours'
    WHEN event_hours BETWEEN 5 AND 6 THEN '5–6 hours'
    WHEN event_hours BETWEEN 7 AND 8 THEN '7–8 hours'
    WHEN event_hours BETWEEN 9 AND 10 THEN '9–10 hours'
    ELSE '11+ hours'
  END AS duration_bucket,
  COUNT(*) AS num_events,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_events
FROM event_durations
GROUP BY duration_bucket
ORDER BY
  CASE duration_bucket
    WHEN '1–2 hours' THEN 1
    WHEN '3–4 hours' THEN 2
    WHEN '5–6 hours' THEN 3
    WHEN '7–8 hours' THEN 4
    WHEN '9–10 hours' THEN 5
    ELSE 6
  END;
