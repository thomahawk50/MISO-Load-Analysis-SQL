-- Q1: Exceedance counts above key thresholds (global percentiles)
WITH base AS (
  SELECT
    interval_start_dt,
    system_load_mw
  FROM `miso-load-analysis.miso.v_actual_load_system`
  WHERE interval_start_dt >= DATETIME '2023-09-01 00:00:00'
    AND interval_start_dt <  DATETIME '2026-01-01 00:00:00'
    AND system_load_mw IS NOT NULL
),
p AS (
  SELECT
    APPROX_QUANTILES(system_load_mw, 1000)[OFFSET(900)] AS p90_mw,
    APPROX_QUANTILES(system_load_mw, 1000)[OFFSET(950)] AS p95_mw,
    APPROX_QUANTILES(system_load_mw, 1000)[OFFSET(990)] AS p99_mw,
    APPROX_QUANTILES(system_load_mw, 1000)[OFFSET(995)] AS p99_5_mw,
    APPROX_QUANTILES(system_load_mw, 1000)[OFFSET(999)] AS p99_9_mw
  FROM base
),
labeled AS (
  SELECT
    b.*,
    p.p90_mw, p.p95_mw, p.p99_mw, p.p99_5_mw, p.p99_9_mw
  FROM base b
  CROSS JOIN p
)
SELECT
  COUNT(*) AS total_hours,
  COUNTIF(system_load_mw >= p90_mw)   AS hours_ge_p90,
  COUNTIF(system_load_mw >= p95_mw)   AS hours_ge_p95,
  COUNTIF(system_load_mw >= p99_mw)   AS hours_ge_p99,
  COUNTIF(system_load_mw >= p99_5_mw) AS hours_ge_p99_5,
  COUNTIF(system_load_mw >= p99_9_mw) AS hours_ge_p99_9,

  SAFE_DIVIDE(COUNTIF(system_load_mw >= p99_mw), COUNT(*)) AS share_ge_p99
FROM labeled;
