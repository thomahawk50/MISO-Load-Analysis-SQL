# MISO System Load Analysis using SQL

## About the Analysis

SQL queries supporting an independent analysis of system load and peak demand behavior across the Midcontinent Independent System Operator (MISO) footprint, September 2023 – December 2025.

## Headline Finding 

Peak demand hours are defined as hours at or above the p99 system load threshold of 110,423 MW, held fixed across the full study period. Of the 205 peak demand hours observed, ~77% occurred in 2025, ~21% in 2024, and ~2% in 2023 (partial-year coverage). Peak demand days show the same pattern, increasing 3.4× from 2024 to 2025.

The increase reflects more frequent entry into extreme load conditions, not longer or more severe individual events — event durations remain bounded at 1–10 hours, with a median of 4.

## Supporting findings

Baseline load is rising. Rolling 12-month median system load grew ~8.6% over the study period; total annual energy consumption rose ~4% from 2024 to 2025.

Peak demand is highly seasonal. ~83% of peak demand days occur in July and August; none occur outside June–September.

Peak demand is a weekday afternoon phenomenon. ~88% of peak days fall on weekdays; ~87% of peak hours occur between 1:00 PM and 7:00 PM EST.

Regional shares are stable under peak conditions. The Central region carries ~50% of system load in non-peak hours and ~52% in peak hours — a modest reweighting, not a structural shift.

## Data

Source: MISO LGI Actual Load (public REST API)

Granularity: Hourly, MW, EST

Records: 20,472 hourly observations

Time range: Sep 1, 2023 – Dec 31, 2025

Regions: Central, North, South

MISO_System_Load_9_1_23-12_31_25.csv contains the system-level series used for sections 1–4. Regional data (used in section 5) was queried directly in BigQuery and is too large to include as a file.

## The Report

The accompanying 40-page report — [MISO System Load Analysis: Growth, Patterns, and Peak Demand (2023–2025)](https://github.com/thomahawk50/MISO-Load-Analysis-SQL/blob/main/MISO%20System%20Load%20Analysis.pdf) — contains methodology, figures, and discussion.

Independent analysis by Thom Johnson, MS Business Analytics
