{{
config(
    tags=['forecast']
)
}}

with

-- Base forecast rows joined to run metadata
base as (
    select
        f.forecast_id,
        f.forecast_run_id,
        f.model_name,
        f.series,
        f.forecast_date,
        f.horizon_periods,
        f.yhat,
        f.yhat_lower,
        f.yhat_upper,
        fr.run_timestamp,
        fr.data_as_of_month,
        fr.forecasting_periods,
        fr.time_grain
    from {{ ref('forecast_output') }} f
    join {{ ref('forecast_run') }} fr
        on f.forecast_run_id = fr.forecast_run_id
),

-- Per model, identify the most recent training cutoff
latest_cutoff as (
    select
        model_name,
        max(data_as_of_month) as data_as_of_month
    from base
    group by model_name
),

-- Within that cutoff, select the most recent run per model
latest_run as (
    select
        forecast_run_id
    from base
    join latest_cutoff using (model_name, data_as_of_month)
    qualify row_number() over (
        partition by base.model_name
        order by run_timestamp desc
    ) = 1
)

-- Return only the rows from the latest run per model
select
    b.*
from base b
join latest_run r
using (forecast_run_id)
