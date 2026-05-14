-- models/forecasting/forecast_run.sql
{{
    config(
        unique_key='forecast_run_id',
        materialized='incremental',
        full_refresh=false
    )
}}

select
    null::varchar(50) as forecast_run_id,
    null::varchar(100) as model_name,
    null::timestamp_ntz as run_timestamp,
    null::date as data_as_of_month,
    null::number as forecasting_periods,
    null::varchar(20) as time_grain,
    null::varchar(255) as forecast_name,
    null::varchar(50) as status,
    null::number as rows_inserted,
    null::timestamp_ntz as start_timestamp,
    null::timestamp_ntz as end_timestamp,
    null::varchar(500) as error_message,
    null::varchar(100) as executed_by
from (values (1))

-- Replace the where false section with logic to actually insert run data when forecasts execute.
where false  -- always returns 0 rows

{% if is_incremental() %}
    -- this prevents the model from running after initial table creation
    and 1=0
{% endif %}