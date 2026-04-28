WITH base AS (
  SELECT interval_start_dt, system_load_mw
  FROM `miso-load-analysis.miso.v_actual_load_system`
  WHERE interval_start_dt >= DATETIME '2023-09-01 00:00:00'
    AND interval_start_dt <  DATETIME '2026-01-01 00:00:00'
),
p99 AS (
  SELECT
    PERCENTILE_CONT(system_load_mw, 0.99) OVER() AS p99_mw
  FROM base
  QUALIFY ROW_NUMBER() OVER (ORDER BY interval_start_dt) = 1
)
SELECT
  COUNT(*) AS total_observed_hours,
  SUM(IF(b.system_load_mw >= p.p99_mw, 1, 0)) AS peak_demand_hours_ge_p99,
  ROUND(100 * SUM(IF(b.system_load_mw >= p.p99_mw, 1, 0)) / COUNT(*), 3) AS share_peak_hours_pct,
  ANY_VALUE(p.p99_mw) AS p99_mw_exact
FROM base b
CROSS JOIN p99 p;
