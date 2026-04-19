{% docs forecast_output__overview %}
Append-only incremental table that stores every forecast row ever produced across
all Snowflake ML forecast model executions. Each run appends a new batch of rows;
historical runs are never updated or deleted (`full_refresh=false`).

The model body is generated entirely by the `run_forecast_model` macro, which calls
the Snowflake ML forecast object (`<model_name>!forecast()`), shapes the raw output,
and attaches surrogate keys. The target forecast model is specified at run time via
the `forecast_model` dbt var.

A `log_forecast_run` post-hook records execution metadata to `forecast_run` after
each successful append.

To query only the current forecast (latest run per model), use
`vw_forecast_output_latest` rather than querying this table directly.

**Running a forecast:**
```
dbt run -s forecast_output --vars '{run_forecast: true, forecast_model: <model_name>}'
```
{% enddocs %}

{% docs forecast_output__forecast_id %}
Surrogate key uniquely identifying a single forecast row. Generated via
`dbt_utils.generate_surrogate_key` over `invocation_id`, `series`, and
`forecast_date`. Guarantees uniqueness within a run and across runs for the same
series and date combination.
{% enddocs %}

{% docs forecast_output__forecast_run_id %}
The dbt `invocation_id` for the run that produced this row. Links to `forecast_run`
where execution metadata (status, timestamps, rows inserted) is recorded by the
`log_forecast_run` post-hook.
{% enddocs %}

{% docs forecast_output__model_name %}
Identifier for the Snowflake ML forecast model that produced this row, matching
`model_name` in `forecast_registry`. Use this column to distinguish rows from
different forecast models in the append-only history.
{% enddocs %}

{% docs forecast_output__series %}
The series partition value returned by Snowflake ML, with enclosing double-quotes
stripped via `trim(series, '"')`. Corresponds to the `series_colname` configured
in `forecast_registry` (e.g., `health_plan`). Note: Snowflake ML may return series
values in uppercase.
{% enddocs %}

{% docs forecast_output__forecast_date %}
The future date being forecasted, cast to a date from the Snowflake ML `ts` output
column. Corresponds to the `timestamp_colname` configured in `forecast_registry`
(e.g., `vb_report_month`).
{% enddocs %}

{% docs forecast_output__horizon_periods %}
The number of periods ahead this row represents, calculated as the row number within
each series ordered by `forecast_date`. Period 1 is one time grain unit after the
training cutoff (`data_as_of_month` in `forecast_run`).
{% enddocs %}

{% docs forecast_output__yhat %}
Snowflake ML point estimate (mean prediction) for the target variable at this
forecast date and series. Cast from the raw `forecast` column returned by the ML
model. Corresponds to the `target_colname` in `forecast_registry`
(e.g., `member_count`).
{% enddocs %}

{% docs forecast_output__yhat_lower %}
Lower bound of the Snowflake ML prediction interval, cast from the raw `lower_bound`
column. May be null if the model did not produce confidence intervals.
{% enddocs %}

{% docs forecast_output__yhat_upper %}
Upper bound of the Snowflake ML prediction interval, cast from the raw `upper_bound`
column. May be null if the model did not produce confidence intervals.
{% enddocs %}
