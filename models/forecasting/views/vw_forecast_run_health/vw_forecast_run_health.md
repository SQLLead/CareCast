{% docs vw_forecast_run_health__overview %}
Operational health monitor for forecast executions. Aggregates `forecast_run` to
the day + model level, surfacing run counts, success/failure rates, and row output
volume. Intended for pipeline monitoring — use this view to detect failed runs,
unexpected output size changes, or models that have stopped executing.

Ordered by most recent run date descending.
{% enddocs %}

{% docs vw_forecast_run_health__run_date %}
Calendar date the forecast runs occurred, truncated from `run_timestamp`. Multiple
runs on the same day for the same model are aggregated into a single row.
{% enddocs %}

{% docs vw_forecast_run_health__model_name %}
Identifier for the Snowflake ML forecast model, matching `model_name` in
`forecast_registry`. Each model appears as a separate row per run date.
{% enddocs %}

{% docs vw_forecast_run_health__total_runs %}
Total number of forecast executions recorded for this model on this run date,
regardless of outcome.
{% enddocs %}

{% docs vw_forecast_run_health__successful_runs %}
Count of executions with `status = 'completed'` on this run date. A healthy
pipeline should have `successful_runs = total_runs`.
{% enddocs %}

{% docs vw_forecast_run_health__failed_runs %}
Count of executions with `status = 'failed'` on this run date. Any non-zero value
warrants investigation.
{% enddocs %}

{% docs vw_forecast_run_health__avg_rows_per_run %}
Average number of forecast rows inserted across all runs on this run date. Useful
for detecting anomalies — a sudden drop may indicate truncated output from the
Snowflake ML model.
{% enddocs %}

{% docs vw_forecast_run_health__max_rows %}
Maximum rows inserted in a single run on this run date. Compare against
`forecasting_periods × series count` to verify full output coverage.
{% enddocs %}

{% docs vw_forecast_run_health__min_rows %}
Minimum rows inserted in a single run on this run date. A value significantly
lower than `max_rows` may indicate a partial or failed execution.
{% enddocs %}
