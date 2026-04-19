{% docs vw_fact_care_gap_ff_fcast__overview %}
Training input view for the care gap forward-fill Snowflake ML forecast model
(`fact_care_gap_ff_snowflake_ml_forecast`). Aggregates `fact_care_gap_ff` to produce
a monthly time series of distinct enrolled member counts per health plan.

This view is registered as the `input_ref` in `forecast_registry` and is consumed
directly by the `actual_plus_forecast` macro to supply the actuals side of the
actuals + forecast union in `vw_actual_plus_forecast`.
{% enddocs %}

{% docs vw_fact_care_gap_ff_fcast__vb_report_month %}
The VB (value-based) report month. Represents the forward-filled reporting period
each care gap row is aligned to, derived from the month bridge in `fact_care_gap_ff`.
Used as the timestamp series column for the Snowflake ML forecast model.
{% enddocs %}

{% docs vw_fact_care_gap_ff_fcast__health_plan %}
The health plan associated with enrolled members for the given report month.
Lowercased to match Snowflake ML series output conventions. Used as the series
partition column for the Snowflake ML forecast model.
{% enddocs %}

{% docs vw_fact_care_gap_ff_fcast__member_count %}
Count of distinct members with at least one forward-filled care gap record in
the given health plan and report month. This is the target variable forecasted
by the Snowflake ML model.
{% enddocs %}
