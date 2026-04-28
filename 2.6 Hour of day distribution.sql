-- Figure 2.5: Hour-of-day distribution of peak demand hours (top 205 system-load hours)
WITH base AS (
  SELECT
    interval_start_dt,
    system_load_mw,
    EXTRACT(HOUR FROM interval_start_dt) AS hour_of_day
  FROM `miso-load-analysis.miso.v_actual_load_system`
  WHERE interval_start_dt >= DATETIME '2023-09-01 00:00:00'
    AND interval_start_dt <  DATETIME '2026-01-01 00:00:00'
),
top205 AS (
  SELECT *
  FROM base
  QUALIFY
    ROW_NUMBER() OVER (ORDER BY system_load_mw DESC, interval_start_dt ASC) <= 205
)
SELECT
  hour_of_day,
  COUNT(*) AS peak_hours,
  SAFE_DIVIDE(COUNT(*), 205) AS share_of_peak_hours
FROM top205
GROUP BY hour_of_day
ORDER BY hour_of_day;
