# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in the `models/forecasting/` folder.

## Purpose

This module is a multi-forecast system built on **Snowflake ML Forecast** (`SNOWFLAKE.ML.FORECAST`). It must support:
1. Creating and training any number of distinct Snowflake ML forecast objects
2. Logging all metadata about each model creation/training event
3. Calling those forecast objects to produce predictions
4. Logging all metadata about each forecast execution
5. Storing the results of every forecast execution (append-only history)

## How It Works

### Lifecycle of a Forecast

```
forecast_registry (seed)        -- defines model config
        |
  create_forecast_model (macro) -- CREATE OR REPLACE SNOWFLAKE.ML.FORECAST
        |
  log_forecast_training (macro) -- records training metadata
        |
  forecast_training             -- stores training log rows (incremental, append)
        |
  run_forecast_model (macro)    -- calls model!forecast(), shapes output
        |
  forecast_output               -- stores forecast results (incremental, append)
        |
  log_forecast_run (macro)      -- inserts run metadata into forecast_run
        |
  forecast_run                  -- stores execution metadata (incremental, append)
```

### Invocation

All forecast models are disabled by default (`enabled=var('run_forecast', false)`). They require explicit dbt vars:

```bash
# Train a model and log training metadata
dbt run -s forecast_training --vars '{run_forecast: true, model_name: fcast_care_gaps__fqhc__backlog_open_care_gaps}'

# Execute a forecast and store results
dbt run -s forecast_output --vars '{run_forecast: true, model_name: fcast_care_gaps__fqhc__backlog_open_care_gaps}'
```

### Key dbt Vars

| Var | Default | Purpose |
|-----|---------|---------|
| `run_forecast` | `false` | Gate flag; must be `true` to run any forecast model |
| `model_name` | none | Model name from `forecast_registry` seed (used by all macros) |
| `forecast_periods` | `12` | Number of future periods to predict (overrides registry value) |

## Directory Structure

```
models/forecasting/
  forecast_output/             -- Generic forecast results table (incremental, append)
  forecast_run/                -- Execution log table (one row per forecast run)
  forecast_training/           -- Training log table (one row per model train)
  views/
    vw_actual_plus_forecast/                -- Actuals + latest forecast union (all enabled models)
    vw_fact_care_gap_ff_fcast/              -- Training input: health plan care gap member counts
    vw_fact_care_gaps_fqhc_fcast/           -- Training input: FQHC-level care gap aggregates
    vw_fact_high_utilizer_fcast/            -- Training input: FQHC utilization (ED, IP, readmissions)
    vw_forecast_output_latest/              -- Latest forecast run per model
    vw_forecast_run_health/                 -- Run health monitoring (daily success/failure counts)
    vw_forecast_run_summary/                -- Run summary reporting (all runs with runtime)
```

## Macros (in `macros/`)

| Macro | Role | Used As |
|-------|------|---------|
| `create_forecast_model(model_name)` | Issues `CREATE OR REPLACE SNOWFLAKE.ML.FORECAST` using config from `forecast_registry` | `pre_hook` |
| `log_forecast_training(model_name)` | Returns a SELECT of training metadata (row counts, date range, column config) | Model body |
| `run_forecast_model(model_name)` | Calls `model!forecast()`, shapes output with surrogate keys and run ID | Model body |
| `log_forecast_run(model_name)` | Inserts execution metadata into `forecast_run` table | `post_hook` |
| `actual_plus_forecast()` | Unions historical actuals with post-cutoff forecasts for all enabled registry models | Model body |

All config-driven macros look up parameters from the `forecast_registry` seed by `model_name`.

### `actual_plus_forecast()` Notes
- Dynamically reads all enabled models from `forecast_registry`
- Generates CTEs per model using the `input_ref` view for actuals and `forecast_output` for predictions
- Trims forecast rows to only those after the actuals cutoff date
- `vw_actual_plus_forecast` must include explicit `-- depends_on: {{ ref(...) }}` hints for every input_ref used by enabled models, since refs are resolved dynamically

## Configuration: forecast_registry Seed

Located at `seeds/reference_files/forecast_registry.csv`, schema defined in `seeds/_seeds.yml` with `schema: forecasting`.

| Column | Description |
|--------|-------------|
| `model_name` | Unique model identifier (PK) |
| `input_ref` | Name of the dbt view used as training input |
| `series_colname` | Column for multi-series partitioning |
| `timestamp_colname` | Date/time column |
| `target_colname` | Value column to forecast |
| `forecast_periods` | Number of periods to predict |
| `time_grain` | Temporal granularity (daily/weekly/monthly/quarterly/yearly) |
| `enabled` | Whether the model is active (`true`/`false`) |

### Currently Enabled Models (10)

| model_name | input_ref | series | target |
|------------|-----------|--------|--------|
| `fact_care_gap_ff_snowflake_ml_forecast` | `vw_fact_care_gap_ff_fcast` | health_plan | member_count |
| `fact_high_utilizer_fcast_snowflake_ml_forecast` | `vw_fact_high_utilizer_fcast` | fqhc | total_ed_visits |
| `fact_care_gaps_fqhc_ml_fcast` | `vw_fact_care_gaps_fqhc_fcast` | fqhc | total_open_care_gaps |
| `fact_care_gaps_fqhc_member_count_ml_fcast` | `vw_fact_care_gaps_fqhc_fcast` | fqhc | member_count |
| `fact_care_gaps_fqhc_open_care_gaps_ml_fcast` | `vw_fact_care_gaps_fqhc_fcast` | fqhc | open_care_gaps_count |
| `fcast_care_gaps__fqhc__backlog_open_care_gaps` | `vw_mart_care_gaps_monthly__by_fqhc` | fqhc_short | backlog_open_care_gaps |
| `fcast_care_gaps__fqhc__eligible_open_care_gaps` | `vw_mart_care_gaps_monthly__by_fqhc` | fqhc_short | eligible_open_care_gaps |
| `fcast_care_gaps__fqhc__eligible_closed_care_gaps` | `vw_mart_care_gaps_monthly__by_fqhc` | fqhc_short | eligible_closed_care_gaps |
| `fcast_care_gaps__fqhc__closure_rate` | `vw_mart_care_gaps_monthly__by_fqhc` | fqhc_short | closure_rate |
| `fcast_care_gaps__fqhc__er_visit_count` | `vw_mart_care_gaps_monthly__by_fqhc` | fqhc_short | er_visit_count |

## Materialization Patterns

- **All models under `forecasting/`** default to `incremental` (set in `dbt_project.yml`)
- **All models under `forecasting/views/`** default to `view`
- `forecast_run` and `forecast_training` use `full_refresh=false` to protect historical data
- `forecast_output` uses `incremental_strategy='append'` (never update/merge)
- All models are tagged `forecast` at the project level

## Naming Conventions

- Training input views: `vw_<data_source_name>_fcast` (e.g., `vw_fact_care_gap_ff_fcast`)
- Snowflake ML model objects: `<descriptive_name>_snowflake_ml_forecast` or `fcast_<domain>__<series>__<target>`
- The `log_forecast_run` macro auto-derives the forecast name from `this.name`

## Current State / Known Issues

1. **`forecast_run.sql` uses `where false`** — the table is created empty; rows are inserted only via `log_forecast_run` post_hooks from `forecast_output`. This is intentional.
2. **`vw_actual_plus_forecast` requires manual `depends_on` hints** — when adding a new model to `forecast_registry` that uses a new `input_ref`, add a corresponding `-- depends_on: {{ ref('...') }}` line to `vw_actual_plus_forecast.sql`.
3. **`create_forecast_model` filters training data** — only series with ≥ 12 historical periods are included via a scoped temporary view. This means sparsely populated series will be silently excluded from training.

## Adding a New Forecast

To add a new forecast (e.g., for a different metric or data source):

1. Add a row to `seeds/reference_files/forecast_registry.csv` with the model configuration
2. Run `dbt seed -s forecast_registry` to update the registry table
3. If the `input_ref` view doesn't exist yet, create it in `views/` with series, timestamp, and target columns
4. If it's a new `input_ref`, add a `-- depends_on: {{ ref('new_view') }}` hint to `vw_actual_plus_forecast.sql`
5. Train the model: `dbt run -s forecast_training --vars '{run_forecast: true, model_name: <new_model_name>}'`
6. Run the forecast: `dbt run -s forecast_output --vars '{run_forecast: true, model_name: <new_model_name>}'`
