-- BigQuery Standard SQL
-- Section 5.1 (Dumbbell): Regional p50 and p99 load (MW)
-- Matches PERCENTILE_CONT definitions via linear interpolation on ordered values.

WITH base AS (
  SELECT
    region,
    CAST(load_mw AS FLOAT64) AS load_mw
  FROM `miso-load-analysis.miso.actual_load_region`
  WHERE interval_start_dt >= DATETIME '2023-09-01 00:00:00'
    AND interval_start_dt <  DATETIME '2026-01-01 00:00:00'
),

arr AS (
  SELECT
    region,
    ARRAY_AGG(load_mw ORDER BY load_mw) AS vals,
    COUNT(*) AS n
  FROM base
  GROUP BY region
),

idx AS (
  SELECT
    region,
    vals,
    n,

    -- Continuous percentile position (0-based index space):
    -- pos = p * (n - 1)
    0.50 * (n - 1) AS pos50,
    0.99 * (n - 1) AS pos99
  FROM arr
)

SELECT
  region,

  -- PERCENTILE_CONT p50 (continuous / interpolated)
  (
    vals[OFFSET(CAST(FLOOR(pos50) AS INT64))] +
    (pos50 - FLOOR(pos50)) *
    (vals[OFFSET(CAST(CEIL(pos50)  AS INT64))] - vals[OFFSET(CAST(FLOOR(pos50) AS INT64))])
  ) AS median_load_mw,

  -- PERCENTILE_CONT p99 (continuous / interpolated)
  (
    vals[OFFSET(CAST(FLOOR(pos99) AS INT64))] +
    (pos99 - FLOOR(pos99)) *
    (vals[OFFSET(CAST(CEIL(pos99)  AS INT64))] - vals[OFFSET(CAST(FLOOR(pos99) AS INT64))])
  ) AS p99_load_mw,

  -- Dumbbell length
  (
    (
      vals[OFFSET(CAST(FLOOR(pos99) AS INT64))] +
      (pos99 - FLOOR(pos99)) *
      (vals[OFFSET(CAST(CEIL(pos99)  AS INT64))] - vals[OFFSET(CAST(FLOOR(pos99) AS INT64))])
    )
    -
    (
      vals[OFFSET(CAST(FLOOR(pos50) AS INT64))] +
      (pos50 - FLOOR(pos50)) *
      (vals[OFFSET(CAST(CEIL(pos50)  AS INT64))] - vals[OFFSET(CAST(FLOOR(pos50) AS INT64))])
    )
  ) AS spread_p99_minus_median_mw,

  n AS hours_n

FROM idx
ORDER BY region;
