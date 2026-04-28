-- BigQuery Standard SQL
WITH base AS (
  SELECT
    DATE(interval_start_dt) AS dt,
    EXTRACT(MONTH FROM interval_start_dt) AS mo,
    EXTRACT(HOUR FROM interval_start_dt) AS hr,
    CAST(system_load_mw AS FLOAT64) AS load_mw
  FROM `miso-load-analysis.miso.v_actual_load_system`
  WHERE EXTRACT(MONTH FROM interval_start_dt) IN (6, 7, 8)
    AND EXTRACT(HOUR FROM interval_start_dt) BETWEEN 0 AND 11
),
peak_days AS (
  SELECT DISTINCT DATE(interval_start_dt) AS dt
  FROM `miso-load-analysis.miso.v_actual_load_system`
  WHERE system_load_mw >= 110423
    AND EXTRACT(MONTH FROM interval_start_dt) IN (6, 7, 8)
),
labeled AS (
  SELECT
    b.hr,
    b.load_mw,
    CASE WHEN p.dt IS NOT NULL THEN 'Peak day' ELSE 'Non-peak day' END AS day_type
  FROM base b
  LEFT JOIN peak_days p ON b.dt = p.dt
),
hour_arrays AS (
  SELECT
    day_type,
    hr,
    ARRAY_AGG(load_mw ORDER BY load_mw) AS vals,
    COUNT(*) AS n,
    AVG(load_mw) AS hourly_avg_load_mw
  FROM labeled
  GROUP BY day_type, hr
)
SELECT
  hr AS hour,
  day_type,
  CASE
    WHEN MOD(n, 2) = 1 THEN vals[OFFSET(DIV(n, 2))]
    ELSE (vals[OFFSET(DIV(n, 2) - 1)] + vals[OFFSET(DIV(n, 2))]) / 2
  END AS hourly_median_load_mw,
  hourly_avg_load_mw,
  n AS num_observations
FROM hour_arrays
ORDER BY hour, day_type;
