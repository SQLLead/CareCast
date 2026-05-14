-- depends_on: {{ ref('vw_fact_care_gap_ff_fcast') }}
-- depends_on: {{ ref('vw_fact_high_utilizer_fcast') }}
-- depends_on: {{ ref('vw_fact_care_gaps_fqhc_fcast') }}
-- depends_on: {{ ref('vw_mart_care_gaps_monthly__by_fqhc') }}

{{
    config(
        materialized='incremental',
        full_refresh=false,
        incremental_strategy='append',
        tags=['forecast'],
        pre_hook="{{ create_forecast_model(var('model_name', none)) }}"
    )
}}

{{ log_forecast_training(var('model_name', none)) }}
