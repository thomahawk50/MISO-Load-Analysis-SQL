-- Q1: Histogram using fixed MW bins (intuitive, report-friendly)
WITH base AS (
  SELECT system_load_mw
  FROM `miso-load-analysis.miso.v_actual_load_system`
  WHERE interval_start_dt >= DATETIME '2023-09-01 00:00:00'
    AND interval_start_dt <  DATETIME '2026-01-01 00:00:00'
    AND system_load_mw IS NOT NULL
)
SELECT
  CAST(FLOOR(system_load_mw / 2000) * 2000 AS INT64) AS bin_start_mw,
  CAST(FLOOR(system_load_mw / 2000) * 2000 + 2000 AS INT64) AS bin_end_mw,
  COUNT(*) AS hours
FROM base
GROUP BY bin_start_mw, bin_end_mw
ORDER BY bin_start_mw;
