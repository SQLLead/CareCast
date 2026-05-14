with 

-- Overview of all forecast runs with key metrics
forecast_run as (
    select
        forecast_run_id,
        model_name,
        run_timestamp,
        data_as_of_month,
        forecasting_periods,
        status,
        rows_inserted,
        datediff('second', start_timestamp, end_timestamp) as runtime_seconds,
        executed_by,
        error_message
    from {{ ref('forecast_run') }}
)

select * from forecast_run 
order by run_timestamp desc