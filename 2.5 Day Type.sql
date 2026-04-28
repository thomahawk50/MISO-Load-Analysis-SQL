WITH ranked_hours AS (
  SELECT
    DATE(interval_start_dt) AS load_date,
    is_weekend,
    system_load_mw,
    interval_start_dt,
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
  CASE
    WHEN is_weekend THEN 'Weekend'
    ELSE 'Weekday'
  END AS day_type,
  COUNT(DISTINCT load_date) AS peak_demand_days
FROM peak_hours
GROUP BY day_type
ORDER BY day_type;
