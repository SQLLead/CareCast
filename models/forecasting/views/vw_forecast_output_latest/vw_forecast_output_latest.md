{% docs vw_forecast_output_latest__overview %}
View that surfaces only the most recent forecast run per model from `forecast_output`.
Joins forecast rows to run metadata from `forecast_run` and applies a two-step
recency filter:

1. Selects the latest `data_as_of_month` (training cutoff) per model — ensuring
   stale forecasts trained on older data are excluded even if run more recently.
2. Within that cutoff, selects the single most recent `run_timestamp` per model.

The result is the authoritative current forecast for each enabled model. Consumed
by `vw_actual_plus_forecast` as the forecast side of the actuals + forecast union.
{% enddocs %}

{% docs vw_forecast_output_latest__forecast_id %}
Surrogate key uniquely identifying a single forecast row (one model + series +
forecast date combination within a run). Sourced from `forecast_output`.
{% enddocs %}

{% docs vw_forecast_output_latest__forecast_run_id %}
Foreign key to `forecast_run`. Identifies the execution that produced this forecast
row. All rows in a given view result share the same `forecast_run_id` per model,
as only the latest run is retained.
{% enddocs %}

{% docs vw_forecast_output_latest__model_name %}
Identifier for the Snowflake ML forecast model, matching the `model_name` in
`forecast_registry`. Use this column to filter results to a specific forecast.
{% enddocs %}

{% docs vw_forecast_output_latest__series %}
The series partition value returned by Snowflake ML. Corresponds to the
`series_colname` configured in `forecast_registry` (e.g., `health_plan`).
Note: Snowflake ML may return series values in uppercase; downstream consumers
such as `vw_actual_plus_forecast` apply `lower()` for consistent matching.
{% enddocs %}

{% docs vw_forecast_output_latest__forecast_date %}
The future period being forecasted. Corresponds to the `timestamp_colname`
configured in `forecast_registry` (e.g., `vb_report_month`).
{% enddocs %}

{% docs vw_forecast_output_latest__horizon_periods %}
The number of periods ahead this row represents relative to the training cutoff.
Period 1 is one time grain unit after `data_as_of_month`.
{% enddocs %}

{% docs vw_forecast_output_latest__yhat %}
Snowflake ML point estimate (mean prediction) for the target variable at this
forecast date and series. Corresponds to the `target_colname` in `forecast_registry`
(e.g., `member_count`).
{% enddocs %}

{% docs vw_forecast_output_latest__yhat_lower %}
Lower bound of the Snowflake ML prediction interval. May be null if the model did
not produce confidence intervals.
{% enddocs %}

{% docs vw_forecast_output_latest__yhat_upper %}
Upper bound of the Snowflake ML prediction interval. May be null if the model did
not produce confidence intervals.
{% enddocs %}

{% docs vw_forecast_output_latest__run_timestamp %}
Timestamp when the forecast execution completed. Sourced from `forecast_run`.
Used as the tiebreaker when multiple runs share the same `data_as_of_month`.
{% enddocs %}

{% docs vw_forecast_output_latest__data_as_of_month %}
The latest actual data month available when the forecast was trained. Represents
the training data cutoff. Used as the primary recency filter — only rows from the
run with the most recent cutoff are returned.
{% enddocs %}

{% docs vw_forecast_output_latest__forecasting_periods %}
The number of future periods the model was asked to forecast, as configured in
`forecast_registry` at run time. Sourced from `forecast_run`.
{% enddocs %}

{% docs vw_forecast_output_latest__time_grain %}
The temporal granularity of the forecast (e.g., `monthly`, `weekly`), as configured
in `forecast_registry`. Sourced from `forecast_run`.
{% enddocs %}
