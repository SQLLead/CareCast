{% docs vw_fact_care_gaps_fqhc_fcast__overview %}
Training input view for the FQHC care gaps forecast model. Aggregates monthly
care gap counts and member counts by FQHC, used as the time-series input to
the Snowflake ML forecast object.
{% enddocs %}

{% docs vw_fact_care_gaps_fqhc_fcast__fqhc_short %}
Short name identifier for the FQHC (Federally Qualified Health Center).
{% enddocs %}

{% docs vw_fact_care_gaps_fqhc_fcast__gap_date %}
Month-truncated date representing the reporting period (first day of each month).
{% enddocs %}

{% docs vw_fact_care_gaps_fqhc_fcast__member_count %}
Count of distinct members with care gap records for the FQHC and month.
{% enddocs %}

{% docs vw_fact_care_gaps_fqhc_fcast__total_open_care_gaps %}
Sum of total open care gaps across all members for the FQHC and month.
{% enddocs %}

{% docs vw_fact_care_gaps_fqhc_fcast__total_closed_care_gaps %}
Sum of total closed care gaps across all members for the FQHC and month.
{% enddocs %}

{% docs vw_fact_care_gaps_fqhc_fcast__open_care_gaps_count %}
Sum of open care gap counts across all members for the FQHC and month.
{% enddocs %}

{% docs vw_fact_care_gaps_fqhc_fcast__closed_care_gaps_count %}
Sum of closed care gap counts across all members for the FQHC and month.
{% enddocs %}
