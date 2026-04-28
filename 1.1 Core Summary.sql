-- Section 1.1: Exact distribution metrics (no rounding)
-- Canonical source + fixed study window

WITH base AS (
  SELECT
    interval_start_dt,
    system_load_mw
  FROM `miso-load-analysis.miso.v_actual_load_system`
  WHERE interval_start_dt >= DATETIME '2023-09-01 00:00:00'
    AND interval_start_dt <  DATETIME '2026-01-01 00:00:00'
)
SELECT
  MIN(system_load_mw) OVER()                          AS min_mw,
  AVG(system_load_mw) OVER()                          AS avg_mw,
  PERCENTILE_CONT(system_load_mw, 0.50) OVER()        AS p50_mw,
  PERCENTILE_CONT(system_load_mw, 0.90) OVER()        AS p90_mw,
  PERCENTILE_CONT(system_load_mw, 0.95) OVER()        AS p95_mw,
  PERCENTILE_CONT(system_load_mw, 0.99) OVER()        AS p99_mw,
  MAX(system_load_mw) OVER()                          AS max_mw
FROM base
QUALIFY ROW_NUMBER() OVER (ORDER BY interval_start_dt) = 1;
