{% docs vw_forecast_run_summary__overview %}
Thin view over `forecast_run` that exposes one row per forecast execution with key
operational metadata. Adds a derived `runtime_seconds` column calculated from
`start_timestamp` and `end_timestamp`. Ordered by most recent run first.

Intended as the primary audit log for forecast executions — use this view to review
run history, inspect errors, confirm training cutoffs, and track execution time trends
across models.
{% enddocs %}

{% docs vw_forecast_run_summary__forecast_run_id %}
Surrogate key uniquely identifying a single forecast execution. Foreign key referenced
by `forecast_output` to link predicted rows back to the run that produced them.
{% enddocs %}

{% docs vw_forecast_run_summary__model_name %}
Identifier for the Snowflake ML forecast model, matching `model_name` in
`forecast_registry`.
{% enddocs %}

{% docs vw_forecast_run_summary__run_timestamp %}
Timestamp when the forecast execution completed. Used as the sort key for this view
and as the tiebreaker in `vw_forecast_output_latest` when multiple runs share the
same `data_as_of_month`.
{% enddocs %}

{% docs vw_forecast_run_summary__data_as_of_month %}
The latest actual data month available when the forecast was executed. Represents
the training data cutoff. Runs with a newer `data_as_of_month` supersede older runs
in `vw_forecast_output_latest`.
{% enddocs %}

{% docs vw_forecast_run_summary__forecasting_periods %}
Number of future periods the model was asked to predict, as configured in
`forecast_registry` at the time of the run.
{% enddocs %}

{% docs vw_forecast_run_summary__status %}
Execution outcome. `completed` indicates the run finished successfully and rows were
inserted into `forecast_output`. `failed` indicates an error occurred; see
`error_message` for details.
{% enddocs %}

{% docs vw_forecast_run_summary__rows_inserted %}
Number of forecast rows written to `forecast_output` during this run. Expected to
equal `forecasting_periods × number of active series`. Null for failed runs.
{% enddocs %}

{% docs vw_forecast_run_summary__runtime_seconds %}
Elapsed time in seconds between `start_timestamp` and `end_timestamp` for the run.
Useful for tracking performance trends and identifying unexpectedly slow executions.
{% enddocs %}

{% docs vw_forecast_run_summary__executed_by %}
The Snowflake user or service account that triggered the forecast run.
{% enddocs %}

{% docs vw_forecast_run_summary__error_message %}
Error detail captured when `status = 'failed'`. Null for successful runs.
{% enddocs %}
