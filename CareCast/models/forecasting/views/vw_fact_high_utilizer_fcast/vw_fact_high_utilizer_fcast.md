{% docs vw_fact_high_utilizer_fcast__overview %}
Training input view for the high utilizer Snowflake ML forecast model. This is an
aggregation query — it summarizes `fact_high_utilizer` to monthly utilization measure
totals per health center, producing the time-series structure required by Snowflake ML.

This view is registered as the `input_ref` in `forecast_registry` and is consumed
directly by the forecasting framework to supply the actuals side of the actuals +
forecast union in `vw_actual_plus_forecast`.
{% enddocs %}

{% docs vw_fact_high_utilizer_fcast__visit_month %}
The calendar month derived by truncating `visit_date` to month granularity. Used as the
timestamp series column for the Snowflake ML forecast model.
{% enddocs %}

{% docs vw_fact_high_utilizer_fcast__dim_fqhc_key %}
Surrogate key for the Federally Qualified Health Center (FQHC). Used as the series
partition column for the Snowflake ML forecast model, enabling per-health-center
predictions.
{% enddocs %}

{% docs vw_fact_high_utilizer_fcast__total_ed_visits %}
Monthly count of total emergency department visits aggregated from `fact_high_utilizer`
for the given health center and visit month.
{% enddocs %}

{% docs vw_fact_high_utilizer_fcast__total_avoidable_ed_visits %}
Monthly count of avoidable emergency department visits aggregated from
`fact_high_utilizer` for the given health center and visit month.
{% enddocs %}

{% docs vw_fact_high_utilizer_fcast__total_ip_stays %}
Monthly count of total inpatient stays aggregated from `fact_high_utilizer` for the
given health center and visit month.
{% enddocs %}

{% docs vw_fact_high_utilizer_fcast__total_readmissions %}
Monthly count of total readmissions aggregated from `fact_high_utilizer` for the given
health center and visit month.
{% enddocs %}
