WITH seasons AS (
  SELECT 'Winter' AS season UNION ALL
  SELECT 'Spring' UNION ALL
  SELECT 'Summer' UNION ALL
  SELECT 'Fall'
),
ranked_hours AS (
  SELECT
    DATE(interval_start_dt) AS load_date,
    season,
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
),
season_totals AS (
  SELECT
    season,
    COUNT(*) AS peak_demand_hours,
    COUNT(DISTINCT load_date) AS peak_demand_days
  FROM peak_hours
  GROUP BY season
),
joined AS (
  SELECT
    s.season,
    COALESCE(t.peak_demand_hours, 0) AS peak_demand_hours,
    COALESCE(t.peak_demand_days, 0) AS peak_demand_days
  FROM seasons s
  LEFT JOIN season_totals t
    USING (season)
),
overall AS (
  SELECT
    SUM(peak_demand_hours) AS total_peak_hours,
    SUM(peak_demand_days) AS total_peak_days
  FROM joined
)
SELECT
  j.season,
  j.peak_demand_hours,
  SAFE_DIVIDE(j.peak_demand_hours, o.total_peak_hours) AS share_of_peak_hours,
  j.peak_demand_days,
  SAFE_DIVIDE(j.peak_demand_days, o.total_peak_days) AS share_of_peak_days
FROM joined j
CROSS JOIN overall o
ORDER BY
  CASE j.season
    WHEN 'Winter' THEN 1
    WHEN 'Spring' THEN 2
    WHEN 'Summer' THEN 3
    WHEN 'Fall' THEN 4
  END;
