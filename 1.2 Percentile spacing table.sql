-- Q1: Percentile spacing table to describe distribution compression/expansion near the top
WITH base AS (
  SELECT system_load_mw
  FROM `miso-load-analysis.miso.v_actual_load_system`
  WHERE interval_start_dt >= DATETIME '2023-09-01 00:00:00'
    AND interval_start_dt <  DATETIME '2026-01-01 00:00:00'
    AND system_load_mw IS NOT NULL
),
q AS (
  SELECT
    APPROX_QUANTILES(system_load_mw, 1000) AS qs
  FROM base
)
SELECT * FROM (
  SELECT 'p10' AS pct, qs[OFFSET(100)]  AS load_mw FROM q UNION ALL
  SELECT 'p25' AS pct, qs[OFFSET(250)]  AS load_mw FROM q UNION ALL
  SELECT 'p50' AS pct, qs[OFFSET(500)]  AS load_mw FROM q UNION ALL
  SELECT 'p75' AS pct, qs[OFFSET(750)]  AS load_mw FROM q UNION ALL
  SELECT 'p90' AS pct, qs[OFFSET(900)]  AS load_mw FROM q UNION ALL
  SELECT 'p95' AS pct, qs[OFFSET(950)]  AS load_mw FROM q UNION ALL
  SELECT 'p99' AS pct, qs[OFFSET(990)]  AS load_mw FROM q UNION ALL
  SELECT 'p99.5' AS pct, qs[OFFSET(995)] AS load_mw FROM q UNION ALL
  SELECT 'p99.9' AS pct, qs[OFFSET(999)] AS load_mw FROM q
)
ORDER BY
  CASE pct
    WHEN 'p10' THEN 10 WHEN 'p25' THEN 25 WHEN 'p50' THEN 50 WHEN 'p75' THEN 75
    WHEN 'p90' THEN 90 WHEN 'p95' THEN 95 WHEN 'p99' THEN 99 WHEN 'p99.5' THEN 995
    WHEN 'p99.9' THEN 999
  END;
