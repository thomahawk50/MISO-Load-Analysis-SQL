WITH ranked_load AS (
  SELECT
    interval_start_dt,
    DATE(interval_start_dt) AS load_date,
    system_load_mw,
    ROW_NUMBER() OVER (ORDER BY system_load_mw DESC) AS load_rank
  FROM `miso-load-analysis.miso.v_actual_load_system`
  WHERE interval_start_dt >= DATETIME '2023-09-01 00:00:00'
    AND interval_start_dt <  DATETIME '2026-01-01 00:00:00'
),

peak_hours AS (
  SELECT DISTINCT
    load_date
  FROM ranked_load
  WHERE load_rank <= 205
)

SELECT
  EXTRACT(MONTH FROM load_date) AS month_num,
  FORMAT_DATE('%B', load_date) AS month_name,
  COUNT(*) AS peak_demand_days
FROM peak_hours
GROUP BY month_num, month_name
ORDER BY month_num;
