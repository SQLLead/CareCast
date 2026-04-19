{% macro actual_plus_forecast() %}

{#
    Unions actuals and forecasts for all enabled registry models.

    Generates a UNION ALL of actual historical data and post-cutoff forecast data
    for every enabled model in forecast_registry. Outputs a standardized schema
    with a model_name column so callers can filter to a specific forecast.

    Output columns:
        model_name                  -- from forecast_registry
        period                      -- timestamp column, aliased to 'period'
        series                      -- series column, aliased to 'series'
        value                       -- target column, aliased to 'value'
        is_forecast                 -- false for actuals, true for forecast rows
        forecast_run_id
        forecast_created_timestamp
        data_as_of_month
        yhat_lower
        yhat_upper

    NOTE: Dynamic refs in the loop below are resolved from forecast_registry.input_ref
    at execute time. Compile-time dependencies are declared explicitly via depends_on
    hints above. Add a new hint when adding a new input_ref to forecast_registry.

    Usage (in the view model file):
        {{ config(tags=['forecast']) }}
        {{ actual_plus_forecast() }}
#}

{# Load enabled forecast models from forecast_registry to drive dynamic CTE generation below. #}
{% set registry_query %}
    select
        model_name,
        input_ref,
        series_colname,
        timestamp_colname,
        target_colname
    from {{ ref('forecast_registry') }}
    where lower(enabled) = 'true'
    order by model_name
{% endset %}

{# At runtime, execute the registry query and halt with a clear error if no enabled models are found. #}
{% if execute %}
    {% set results = run_query(registry_query) %}

    {% if results | length == 0 %}
        {{ exceptions.raise_compiler_error(
            "actual_plus_forecast: no enabled models found in forecast_registry"
        ) }}
    {% endif %}

with

{# Pull the latest forecast output for all models into a single CTE for joining below. #}
forecast_all as (
    select
        model_name,
        forecast_date           as period,
        lower(series)           as series,
        yhat                    as value,
        true                    as is_forecast,
        forecast_run_id,
        run_timestamp           as forecast_created_timestamp,
        data_as_of_month,
        yhat_lower,
        yhat_upper
    from {{ ref('vw_forecast_output_latest') }}
),

{# For each enabled model, extract registry columns and build a SQL-safe slug for CTE naming. #}
    {% for row in results.rows %}
        {% set mn         = row['MODEL_NAME'] %}
        {% set input_ref  = row['INPUT_REF'] %}
        {% set ts_col     = row['TIMESTAMP_COLNAME'] %}
        {% set series_col = row['SERIES_COLNAME'] %}
        {% set target_col = row['TARGET_COLNAME'] %}
        {% set slug       = mn | replace('-', '_') | replace(' ', '_') %}

{# Pull historical actuals for this model, mapping registry-defined columns to the standard output schema. #}
actual_{{ slug }} as (
    select
        '{{ mn }}'              as model_name,
        {{ ts_col }}            as period,
        {{ series_col }}        as series,
        {{ target_col }}        as value,
        false                   as is_forecast,
        null::string            as forecast_run_id,
        null::timestamp         as forecast_created_timestamp,
        null::date              as data_as_of_month,
        null::number            as yhat_lower,
        null::number            as yhat_upper
    from {{ ref(input_ref) }}
),

{# Find the most recent actual period to use as the cutoff between actuals and forecast rows. #}
last_actual_{{ slug }} as (
    select max(period) as last_actual_period
    from actual_{{ slug }}
),

{# Trim forecast rows to only those beyond the last actual period, avoiding overlap with historical data. #}
forecast_after_actuals_{{ slug }} as (
    select f.*
    from forecast_all f
    join last_actual_{{ slug }} la
    on f.period > la.last_actual_period
    where lower(f.model_name) = lower('{{ mn }}')
),

    {% endfor %}

{# Union actuals and trimmed forecasts for every enabled model into a single result set. #}
unioned as (
    {% for row in results.rows %}
        {% set mn   = row['MODEL_NAME'] %}
        {% set slug = mn | replace('-', '_') | replace(' ', '_') %}
        select * from actual_{{ slug }}
        union all
        select * from forecast_after_actuals_{{ slug }}
        {% if not loop.last %}union all{% endif %}
    {% endfor %}
)

select * from unioned

{% endif %}

{% endmacro %}
