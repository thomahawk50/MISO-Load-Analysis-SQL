-- BigQuery Standard SQL
-- Exact monthly median (from hourly) + exact 12-month trailing rolling median (from monthly medians)
-- Adds growth since the first available rolling month (MW + %)
-- No PERCENTILE_CONT aggregate. No correlated subqueries.

WITH base AS (
  SELECT
    DATE_TRUNC(DATE(interval_start_dt), MONTH) AS month,
    CAST(system_load_mw AS FLOAT64) AS system_load_mw
  FROM `miso-load-analysis.miso.v_actual_load_system`
  WHERE interval_start_dt >= DATETIME '2023-09-01 00:00:00'
    AND interval_start_dt <  DATETIME '2026-01-01 00:00:00'
),

-- 1) Exact monthly median from hourly data (manual median from sorted array)
monthly AS (
  SELECT
    month,
    CASE
      WHEN MOD(n, 2) = 1 THEN loads[OFFSET(DIV(n, 2))]
      ELSE (loads[OFFSET(DIV(n, 2) - 1)] + loads[OFFSET(DIV(n, 2))]) / 2
    END AS monthly_median_load_mw
  FROM (
    SELECT
      month,
      ARRAY_AGG(system_load_mw ORDER BY system_load_mw) AS loads,
      COUNT(*) AS n
    FROM base
    GROUP BY month
  )
),

-- 2) Trailing 12-month windows via JOIN (de-correlated)
windows AS (
  SELECT
    m.month AS month,
    m.monthly_median_load_mw AS monthly_median_load_mw,
    ARRAY_AGG(m2.monthly_median_load_mw ORDER BY m2.monthly_median_load_mw) AS win_vals,
    COUNT(*) AS months_in_window,
    DATE_DIFF(MAX(m2.month), MIN(m2.month), MONTH) AS window_month_span
  FROM monthly m
  JOIN monthly m2
    ON m2.month BETWEEN DATE_SUB(m.month, INTERVAL 11 MONTH) AND m.month
  GROUP BY
    m.month,
    m.monthly_median_load_mw
),

-- 3) Compute exact rolling 12-month median (only full contiguous windows)
rolling AS (
  SELECT
    month,
    monthly_median_load_mw,
    (win_vals[OFFSET(5)] + win_vals[OFFSET(6)]) / 2 AS rolling_12mo_median_load_mw
  FROM windows
  WHERE months_in_window = 12
    AND window_month_span = 11
),

-- 4) Attach baseline rolling start and compute growth metrics
final AS (
  SELECT
    month,
    monthly_median_load_mw,
    rolling_12mo_median_load_mw,
    FIRST_VALUE(rolling_12mo_median_load_mw) OVER (ORDER BY month) AS rolling_start_median_mw
  FROM rolling
)

SELECT
  month,
  monthly_median_load_mw,
  rolling_12mo_median_load_mw,
  rolling_start_median_mw,
  (rolling_12mo_median_load_mw - rolling_start_median_mw) AS rolling_growth_mw,
  SAFE_DIVIDE(rolling_12mo_median_load_mw - rolling_start_median_mw, rolling_start_median_mw) AS rolling_growth_pct
FROM final
ORDER BY month;
