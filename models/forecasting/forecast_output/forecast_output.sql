-- depends_on: {{ ref('vw_fact_care_gap_ff_fcast') }}
-- depends_on: {{ ref('vw_fact_high_utilizer_fcast') }}
-- depends_on: {{ ref('vw_fact_care_gaps_fqhc_fcast') }}
-- depends_on: {{ ref('vw_mart_care_gaps_monthly__by_fqhc') }}

{{
    config(
        materialized='incremental',
        full_refresh=false,
        post_hook="{{ log_forecast_run(var('model_name', none)) }}",
        incremental_strategy='append',
        tmp_relation_type='table'
    )
}}

{{ run_forecast_model(var('model_name', none)) }}
