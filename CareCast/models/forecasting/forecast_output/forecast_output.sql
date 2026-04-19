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
