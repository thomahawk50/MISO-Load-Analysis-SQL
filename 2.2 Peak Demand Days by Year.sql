WITH ranked_hours AS (
  SELECT
    interval_start_dt,
    DATE(interval_start_dt) AS load_date,
    year,
    system_load_mw,
    ROW_NUMBER() OVER (
      ORDER BY system_load_mw DESC, interval_start_dt
    ) AS load_rank
  FROM `miso-load-analysis.miso.v_actual_load_system`
  WHERE interval_start_dt >= DATETIME '2023-09-01 00:00:00'
    AND interval_start_dt <  DATETIME '2026-01-01 00:00:00'
),

peak_hours AS (
  SELECT *
  FROM ranked_hours
  WHERE load_rank <= 205
)

SELECT
  year,
  COUNT(DISTINCT load_date) AS peak_demand_days
FROM peak_hours
GROUP BY year
ORDER BY year;
