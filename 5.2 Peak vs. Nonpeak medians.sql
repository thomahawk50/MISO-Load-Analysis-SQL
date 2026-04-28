-- BigQuery Standard SQL
-- Section 5.2: Regional behavior during system peak demand hours (Peak vs Non-peak)
--
-- Core idea:
-- 1) Use the LOCKED system peak definition: top 205 system load hours (p99 set), threshold = 110,423 MW.
-- 2) Classify every hour in the study window as Peak Hour vs Non-peak Hour based on that set.
-- 3) Join regional hourly load to the system hour classification.
-- 4) Compute, by region and hour_type:
--    - median regional load (MW)
--    - median regional share of system load (regional_load / system_load)
-- 5) Return a clean summary and (optionally) a Peak vs Non-peak comparison with deltas.

DECLARE start_dt DATETIME DEFAULT DATETIME '2023-09-01 00:00:00';
DECLARE end_dt   DATETIME DEFAULT DATETIME '2026-01-01 00:00:00';

WITH system_base AS (
  SELECT
    interval_start_dt,
    CAST(system_load_mw AS FLOAT64) AS system_load_mw
  FROM `miso-load-analysis.miso.v_actual_load_system`
  WHERE interval_start_dt >= start_dt
    AND interval_start_dt <  end_dt
),

-- LOCKED peak set: top 205 system-load hours (the p99 "peak demand hours" used throughout the report)
peak_hours AS (
  SELECT interval_start_dt
  FROM (
    SELECT
      interval_start_dt,
      system_load_mw,
      ROW_NUMBER() OVER (ORDER BY system_load_mw DESC, interval_start_dt ASC) AS rn
    FROM system_base
  )
  WHERE rn <= 205
),

system_labeled AS (
  SELECT
    sb.interval_start_dt,
    sb.system_load_mw,
    CASE
      WHEN ph.interval_start_dt IS NOT NULL THEN 'Peak hour'
      ELSE 'Non-peak hour'
    END AS hour_type
  FROM system_base sb
  LEFT JOIN peak_hours ph
    USING (interval_start_dt)
),

region_base AS (
  SELECT
    interval_start_dt,
    region,
    CAST(load_mw AS FLOAT64) AS regional_load_mw
  FROM `miso-load-analysis.miso.actual_load_region`
  WHERE interval_start_dt >= start_dt
    AND interval_start_dt <  end_dt
    AND load_mw IS NOT NULL
),

joined AS (
  SELECT
    r.interval_start_dt,
    r.region,
    sl.hour_type,
    r.regional_load_mw,
    sl.system_load_mw,
    SAFE_DIVIDE(r.regional_load_mw, sl.system_load_mw) AS regional_share
  FROM region_base r
  JOIN system_labeled sl
    USING (interval_start_dt)
),

-- Exact PERCENTILE_CONT implemented via ordered arrays + interpolation (BigQuery-safe)
arr AS (
  SELECT
    region,
    hour_type,
    ARRAY_AGG(regional_load_mw ORDER BY regional_load_mw) AS vals_load,
    ARRAY_AGG(regional_share    ORDER BY regional_share)  AS vals_share,
    COUNT(*) AS n_hours
  FROM joined
  GROUP BY region, hour_type
),

idx AS (
  SELECT
    region,
    hour_type,
    vals_load,
    vals_share,
    n_hours,
    0.50 * (n_hours - 1) AS pos50
  FROM arr
),

medians AS (
  SELECT
    region,
    hour_type,
    n_hours,

    -- median regional load (MW), exact PERCENTILE_CONT(0.50)
    (
      vals_load[OFFSET(CAST(FLOOR(pos50) AS INT64))] +
      (pos50 - FLOOR(pos50)) *
      (vals_load[OFFSET(CAST(CEIL(pos50)  AS INT64))] - vals_load[OFFSET(CAST(FLOOR(pos50) AS INT64))])
    ) AS median_regional_load_mw,

    -- median regional share (unitless), exact PERCENTILE_CONT(0.50)
    (
      vals_share[OFFSET(CAST(FLOOR(pos50) AS INT64))] +
      (pos50 - FLOOR(pos50)) *
      (vals_share[OFFSET(CAST(CEIL(pos50)  AS INT64))] - vals_share[OFFSET(CAST(FLOOR(pos50) AS INT64))])
    ) AS median_regional_share
  FROM idx
),

-- Optional: pivot Peak vs Non-peak into one row per region + deltas
pivoted AS (
  SELECT
    region,

    MAX(IF(hour_type = 'Non-peak hour', n_hours, NULL)) AS nonpeak_hours,
    MAX(IF(hour_type = 'Peak hour',     n_hours, NULL)) AS peak_hours,

    MAX(IF(hour_type = 'Non-peak hour', median_regional_load_mw, NULL)) AS nonpeak_median_load_mw,
    MAX(IF(hour_type = 'Peak hour',     median_regional_load_mw, NULL)) AS peak_median_load_mw,

    MAX(IF(hour_type = 'Non-peak hour', median_regional_share, NULL)) AS nonpeak_median_share,
    MAX(IF(hour_type = 'Peak hour',     median_regional_share, NULL)) AS peak_median_share
  FROM medians
  GROUP BY region
)

SELECT
  region,

  nonpeak_hours,
  peak_hours,

  nonpeak_median_load_mw,
  peak_median_load_mw,
  (peak_median_load_mw - nonpeak_median_load_mw) AS delta_median_load_mw,
  SAFE_DIVIDE(peak_median_load_mw - nonpeak_median_load_mw, nonpeak_median_load_mw) AS pct_change_median_load,

  nonpeak_median_share,
  peak_median_share,
  (peak_median_share - nonpeak_median_share) AS delta_share_points

FROM pivoted
ORDER BY region;
