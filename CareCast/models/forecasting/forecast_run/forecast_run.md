{% docs forecast_run %}
Table tracking all forecast run executions and their metadata. This table maintains a complete audit trail of every forecast run including execution timing, status, row counts, and any errors encountered during processing.
{% enddocs %}

{% docs forecast_run__forecast_run_id %}
Unique identifier for each forecast run execution. Serves as the primary key of the table, guaranteeing uniqueness across all forecast runs.
{% enddocs %}

{% docs forecast_run__run_timestamp %}
Timestamp when the forecast run was initiated. This timestamp is set at the beginning of the forecast execution process.
{% enddocs %}

{% docs forecast_run__forecast_name %}
Name or identifier of the forecast being executed. This field uniquely identifies which forecast model or process was run.
{% enddocs %}

{% docs forecast_run__status %}
Current status of the forecast run execution. Accepted values: 'pending' (queued for execution), 'running' (currently executing), 'completed' (finished successfully), 'failed' (terminated with error).
{% enddocs %}

{% docs forecast_run__rows_inserted %}
Number of rows inserted or updated during the forecast run execution. Represents the volume of data modified in the target table(s). Must be greater than or equal to zero.
{% enddocs %}

{% docs forecast_run__start_timestamp %}
Timestamp when the forecast run started processing. Marks the moment when actual forecast computation begins.
{% enddocs %}

{% docs forecast_run__end_timestamp %}
Timestamp when the forecast run completed processing. Marks the moment when the forecast execution finished, whether successfully or with an error. Can be used to calculate execution duration.
{% enddocs %}

{% docs forecast_run__error_message %}
Error message captured if the forecast run failed during execution. Null if the run completed successfully. Contains diagnostic information for troubleshooting failed forecasts.
{% enddocs %}

{% docs forecast_run__executed_by %}
User or system identifier that initiated the forecast run. Can be a username, service account, or automated system name.
{% enddocs %}