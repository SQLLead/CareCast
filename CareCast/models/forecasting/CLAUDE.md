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
  forecast_training_history     -- stores training log rows (incremental, append)
        |
  run_forecast_model (macro)    -- calls model!forecast(), shapes output
        |
  forecast output model         -- stores forecast results (incremental, append)
        |
  log_forecast_run (macro)      -- inserts run metadata into forecast_run
        |
  forecast_run                  -- stores execution metadata (incremental, append)
```

### Invocation

All forecast models are disabled by default (`enabled=var('run_forecast', false)`). They require explicit dbt vars:

```bash
# Train a model and log training metadata
dbt run -s forecast_training_history --vars '{run_forecast: true, forecast_model: fact_care_gap_ff_fcast_model}'

# Execute a forecast and store results
dbt run -s fact_care_gap_ff_fcast --vars '{run_forecast: true, forecast_periods: 12}'

# Generic forecast execution (via forecast_output + run_forecast_model macro)
dbt run -s forecast_output --vars '{run_forecast: true, forecast_model: fact_care_gap_ff_fcast_model}'
```

### Key dbt Vars

| Var | Default | Purpose |
|-----|---------|---------|
| `run_forecast` | `false` | Gate flag; must be `true` to run any forecast model |
| `forecast_model` | none | Model name from `forecast_registry` seed (used by macros) |
| `forecast_periods` | `12` | Number of future periods to predict |

## Directory Structure

```
models/forecasting/
  forecast_run/                -- Execution log table (one row per forecast run)
  forecast_training_history/   -- Training log table (one row per model train)
  forecasts/
    fact_care_gap_ff_fcast/    -- Care gap forecast results (specific implementation)
    forecast_output/           -- Generic forecast output (uses run_forecast_model macro)
  ml/
    fact_care_gap_ff_fcast_model_log/  -- Legacy/specific model creation log
  views/
    vw_fact_care_gap_ff_fcast/                              -- Training input view (aggregates fact_care_gap_ff)
    vw_fact_care_gap_ff_fcast_actual_plus_forecast/          -- Actuals + forecast union
    vw_fact_care_gap_ff_fcast_member_count_forecast_latest/  -- Latest forecast run only
    vw_forecast_run_health/                                  -- Run health monitoring
    vw_forecast_run_summary/                                 -- Run summary reporting
```

## Macros (in `macros/`)

| Macro | Role | Used As |
|-------|------|---------|
| `create_forecast_model(model_name)` | Issues `CREATE OR REPLACE SNOWFLAKE.ML.FORECAST` using config from `forecast_registry` | `pre_hook` |
| `log_forecast_training(model_name)` | Returns a SELECT of training metadata (row counts, date range, column config) | Model body |
| `run_forecast_model(model_name)` | Calls `model!forecast()`, shapes output with surrogate keys and run ID | Model body |
| `log_forecast_run(...)` | Inserts execution metadata into `forecast_run` table | `post_hook` |

All config-driven macros look up parameters from the `forecast_registry` seed by `model_name`.

## Configuration: forecast_registry Seed

Defined in `seeds/_seeds.yml` with schema `forecasting`. Each row configures one Snowflake ML forecast model:

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

**Note:** The CSV file for this seed does not yet exist in `seeds/`. It needs to be created before the config-driven macros will work.

## Materialization Patterns

- **All models under `forecasting/`** default to `incremental` (set in `dbt_project.yml`)
- **All models under `forecasting/views/`** default to `view`
- `forecast_run` and `forecast_training_history` use `full_refresh=false` to protect historical data
- Forecast output models use `incremental_strategy='append'` (never update/merge)
- All models are tagged `forecast` at the project level

## Naming Conventions

- Training input views: `vw_<forecast_table_name>` (e.g., `vw_fact_care_gap_ff_fcast`)
- Snowflake ML model objects: `<forecast_table_name>_model` (e.g., `fact_care_gap_ff_fcast_model`)
- The `log_forecast_run` macro auto-derives view name as `vw_` + `this.name` and model name as `this.name` + `_model`

## Current State / Known Issues

1. **`forecast_output` model is commented out** — the `run_forecast_model` macro call is wrapped in `{# #}` comment tags. This is the generic version; `fact_care_gap_ff_fcast` has a hardcoded equivalent that works.
2. **`fact_care_gap_ff_fcast` has a hardcoded database/schema** — the forecast model call references `data_warehouse_dev.eb_forecasting.fact_care_gap_ff_fcast_model` instead of using dynamic resolution.
3. **`forecast_registry` seed CSV is missing** — the schema is defined in `_seeds.yml` but no CSV file exists yet in `seeds/`.
4. **`ml/fact_care_gap_ff_fcast_model_log`** is an older specific implementation. The generic `forecast_training_history` model (which uses `create_forecast_model` + `log_forecast_training` macros) is the preferred approach.
5. **`forecast_run.sql` uses `where false`** — the table is created empty; rows are inserted only via `log_forecast_run` post_hooks from forecast output models.
6. **YML file typo** — `views/vw_fact_care_gap_ff_fcast/ww_fact_care_gap_ff_fcast.yml` starts with `ww_` instead of `vw_`.

## Adding a New Forecast

To add a new forecast (e.g., for a different metric or data source):

1. Add a row to the `forecast_registry` seed CSV with the model configuration
2. Create a training input view in `views/` that prepares the time-series data (must have series, timestamp, and target columns)
3. Either:
   - Use the generic `forecast_output` model (once uncommented/fixed), or
   - Create a specific forecast model in `forecasts/` following the `fact_care_gap_ff_fcast` pattern
4. The macros handle model creation, execution, and logging automatically based on the registry config
