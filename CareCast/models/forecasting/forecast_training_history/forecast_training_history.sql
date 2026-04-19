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