{% macro run_forecast_model(model_name) %}

{#
    Calls a Snowflake ML forecast model and returns the forecast rows.
    Looks up model configuration from the forecast_registry seed.

    Args:
        model_name: Name of the model as defined in forecast_registry seed.

    Usage (in a model file):
        {{ run_forecast_model(var('model_name')) }}

    Invocation:
        dbt run --select forecast_output --vars '{model_name: fact_care_gap_ff_fcast_model}'
#}

{% if not execute %}
    {# Parse phase: return a schema stub so the incremental table can be created/compiled correctly. #}
    select
        null::varchar      as forecast_id,
        null::varchar      as forecast_run_id,
        null::varchar      as model_name,
        null::varchar      as series,
        null::date         as forecast_date,
        null::integer      as horizon_periods,
        null::number(38,9) as yhat,
        null::number(38,9) as yhat_lower,
        null::number(38,9) as yhat_upper
    where false

{% elif not model_name %}
    {{ log("run_forecast_model(): skipping execution, no model_name provided.", info=true) }}
    select
        null::varchar      as forecast_id,
        null::varchar      as forecast_run_id,
        null::varchar      as model_name,
        null::varchar      as series,
        null::date         as forecast_date,
        null::integer      as horizon_periods,
        null::number(38,9) as yhat,
        null::number(38,9) as yhat_lower,
        null::number(38,9) as yhat_upper
    where false

{% else %}

    {# Execute phase: look up config from forecast_registry and run the forecast. #}
    {% set config_query %}
        select * from {{ ref('forecast_registry') }}
        where model_name = '{{ model_name }}'
        and enabled = 'true'
    {% endset %}

    {% set results = run_query(config_query) %}

    {% if results | length == 0 %}
        {{ exceptions.raise_compiler_error(
            "Forecast model '" ~ model_name ~ "' not found or not enabled in forecast_registry"
        ) }}
    {% endif %}

    {% set row = results.rows[0] %}
    {% set db = this.database %}
    {% set schema = this.schema %}
    {% set model_fqn = db ~ '.' ~ schema ~ '.' ~ model_name %}
    {% set forecast_periods = row['FORECAST_PERIODS'] %}

with

forecast_base as (
    select
        trim(series, '"') as series,
        to_date(ts) as forecast_date,
        to_number(forecast) as yhat,
        to_number(lower_bound) as yhat_lower,
        to_number(upper_bound) as yhat_upper,
        row_number() over (partition by series order by ts) as horizon_periods
    from table({{ model_fqn }}!forecast(
        forecasting_periods => {{ forecast_periods }}
    ))
),

final as (
    select

        {{ dbt_utils.generate_surrogate_key([
            "'{{ invocation_id }}'",
            'series',
            'forecast_date'
        ]) }} as forecast_id,

        '{{ invocation_id }}' as forecast_run_id,
        '{{ model_name }}' as model_name,
        series,
        forecast_date,
        horizon_periods,
        yhat,
        yhat_lower,
        yhat_upper

    from forecast_base
)

select * from final
{% endif %}

{% endmacro %}
