-- Section 2.1: Peak demand hours by year
-- Uses the fixed p99 threshold from Section 1 (no recomputation)

WITH base AS (
  SELECT
    year,
    system_load_mw
  FROM `miso-load-analysis.miso.v_actual_load_system`
  WHERE interval_start_dt >= DATETIME '2023-09-01 00:00:00'
    AND interval_start_dt <  DATETIME '2026-01-01 00:00:00'
),
peak_hours AS (
  SELECT *
  FROM base
  WHERE system_load_mw >= 110422.778  -- exact p99 threshold (unrounded)
),
totals AS (
  SELECT COUNT(*) AS total_peak_hours
  FROM peak_hours
)
SELECT
  ph.year,
  COUNT(*) AS peak_demand_hours,
  ROUND(100 * COUNT(*) / ANY_VALUE(t.total_peak_hours), 1) AS share_of_peak_hours_pct
FROM peak_hours ph
CROSS JOIN totals t
GROUP BY ph.year
ORDER BY ph.year;
