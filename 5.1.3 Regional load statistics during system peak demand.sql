-- BigQuery Standard SQL
-- Section 5.2A: Regional load statistics during system peak demand hours (205 hours)

WITH peak_hours AS (
  SELECT
    interval_start_dt
  FROM `miso-load-analysis.miso.v_actual_load_system`
  WHERE interval_start_dt >= DATETIME '2023-09-01 00:00:00'
    AND interval_start_dt <  DATETIME '2026-01-01 00:00:00'
    AND system_load_mw >= 110423
),

base AS (
  SELECT
    r.interval_start_dt,
    r.region,
    CAST(r.load_mw AS FLOAT64) AS load_mw
  FROM `miso-load-analysis.miso.actual_load_region` r
  INNER JOIN peak_hours p
    ON r.interval_start_dt = p.interval_start_dt
)

SELECT
  region,

  COUNT(*) OVER (PARTITION BY region)                         AS peak_hours_n,
  MIN(load_mw) OVER (PARTITION BY region)                     AS min_mw,
  AVG(load_mw) OVER (PARTITION BY region)                     AS avg_mw,
  PERCENTILE_CONT(load_mw, 0.50) OVER (PARTITION BY region)   AS p50_mw,
  PERCENTILE_CONT(load_mw, 0.90) OVER (PARTITION BY region)   AS p90_mw,
  PERCENTILE_CONT(load_mw, 0.95) OVER (PARTITION BY region)   AS p95_mw,
  PERCENTILE_CONT(load_mw, 0.99) OVER (PARTITION BY region)   AS p99_mw,
  MAX(load_mw) OVER (PARTITION BY region)                     AS max_mw

FROM base
QUALIFY ROW_NUMBER() OVER (PARTITION BY region ORDER BY interval_start_dt) = 1
ORDER BY region;
