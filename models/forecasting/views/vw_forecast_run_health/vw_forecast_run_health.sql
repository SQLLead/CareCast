with 

-- Identify failed runs, missing forecasts, or anomalies
forecast_run as (
    select
        date_trunc('day', run_timestamp) as run_date,
        model_name,
        count(*) as total_runs,
        sum(case when status = 'completed' then 1 else 0 end) as successful_runs,
        sum(case when status = 'failed' then 1 else 0 end) as failed_runs,
        avg(rows_inserted) as avg_rows_per_run,
        max(rows_inserted) as max_rows,
        min(rows_inserted) as min_rows
    from {{ ref('forecast_run') }}
    group by 1, 2
)

select * 
from forecast_run
order by run_date desc, model_name