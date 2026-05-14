{% docs vw_actual_plus_forecast__overview %}
Generic view that unions actual historical values with post-cutoff forecast values
for every enabled model in `forecast_registry`. Driven entirely by the
`actual_plus_forecast` macro — no model-specific logic lives in this file.

Each row is either an actual observation (sourced from the model's `input_ref` view)
or a forecasted value (sourced from `vw_forecast_output_latest`). Forecast rows are
only included for periods after the last available actual, preventing overlap.

Output is standardized across all forecast models using common column names
(`model_name`, `period`, `series`, `value`). Filter on `model_name` to scope results
to a specific forecast.

**Adding a new forecast:** register the model in `forecast_registry` and add a
`-- depends_on: ref('input_ref_value') hint to this view's `.sql` file. No
changes to the macro are needed.
{% enddocs %}

{% docs vw_actual_plus_forecast__model_name %}
Identifier for the forecast model, as defined in `forecast_registry`. Use this column
to filter results to a specific forecast (e.g., `fact_care_gap_ff_snowflake_ml_forecast`).
{% enddocs %}

{% docs vw_actual_plus_forecast__period %}
The time period for the row, standardized from each model's `timestamp_colname` in
`forecast_registry`. Represents the reporting month (or other time grain) for both
actual and forecast rows.
{% enddocs %}

{% docs vw_actual_plus_forecast__series %}
The series partition for the row, standardized from each model's `series_colname` in
`forecast_registry`. For care gap forecasts this is `health_plan`. Lowercased to match
Snowflake ML series output conventions.
{% enddocs %}

{% docs vw_actual_plus_forecast__value %}
The observed or predicted numeric value, standardized from each model's `target_colname`
in `forecast_registry`. For actual rows this is the true historical value; for forecast
rows this is `yhat` (the point estimate) from Snowflake ML.
{% enddocs %}

{% docs vw_actual_plus_forecast__is_forecast %}
Boolean flag indicating the source of the row. `false` for actual historical observations;
`true` for Snowflake ML forecast rows. All forecast rows appear strictly after the last
actual period for their model and series.
{% enddocs %}

{% docs vw_actual_plus_forecast__forecast_run_id %}
Surrogate key identifying the specific forecast execution that produced this row.
Null for actual rows. Joins to `forecast_run` for execution metadata.
{% enddocs %}

{% docs vw_actual_plus_forecast__forecast_created_timestamp %}
Timestamp when the forecast run was executed (`run_timestamp` from `forecast_output`).
Null for actual rows.
{% enddocs %}

{% docs vw_actual_plus_forecast__data_as_of_month %}
The latest actual data month available at the time the forecast was generated.
Represents the training data cutoff. Null for actual rows.
{% enddocs %}

{% docs vw_actual_plus_forecast__yhat_lower %}
Lower bound of the Snowflake ML prediction interval for forecast rows. Null for actual
rows.
{% enddocs %}

{% docs vw_actual_plus_forecast__yhat_upper %}
Upper bound of the Snowflake ML prediction interval for forecast rows. Null for actual
rows.
{% enddocs %}
