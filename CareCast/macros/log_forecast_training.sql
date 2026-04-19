{% macro log_forecast_training(model_name=none) %}

{#
    Returns a SELECT of training metadata for a forecast model.
    Looks up model configuration from the forecast_registry seed.

    Args:
        model_name: Name of the model as defined in forecast_registry seed.

    Usage (as model body):
        {{ log_forecast_training(var('model_name')) }}
#}

{% if not model_name %}
    {{ log("log_forecast_training(): skipping execution, no model_name provided.", info=true) }}
    {{ return('') }}
{% endif %}

{% set config_query %}
    select * from {{ ref('forecast_registry') }}
    where lower(model_name) = lower('{{ model_name }}')
    and enabled::boolean = true
{% endset %}

{% if execute %}
    {% set results = run_query(config_query) %}

    {% if results.rows | length == 0 %}
        {{ exceptions.raise_compiler_error(
            "Forecast model '" ~ model_name ~ "' not found or not enabled in forecast_registry"
        ) }}
    {% endif %}

    {% set row = results.rows[0] %}
    {% set target_cols = [] %}
    {% for r in results.rows %}
        {% do target_cols.append(r['TARGET_COLNAME']) %}
    {% endfor %}
    {% set db = this.database %}
    {% set schema = this.schema %}
    {% set model_fqn = db ~ '.' ~ schema ~ '.' ~ model_name %}
    {% set input_table = db ~ '.' ~ schema ~ '.' ~ row['INPUT_REF'] %}

select
    '{{ model_name }}' as model_name,
    '{{ model_fqn }}' as forecast_model_fqn,
    current_timestamp() as training_timestamp,
    'ACTIVE' as model_status,
    'SNOWFLAKE_ML_FORECAST' as model_type,
    '{{ row['INPUT_REF'] }}' as input_ref,
    '{{ row['SERIES_COLNAME'] }}' as series_colname,
    '{{ row['TIMESTAMP_COLNAME'] }}' as timestamp_colname,
    '{{ target_cols | join(", ") }}' as target_colname,
    count(*) as training_rows,
    min({{ row['TIMESTAMP_COLNAME'] }})::date as training_start_date,
    max({{ row['TIMESTAMP_COLNAME'] }})::date as training_end_date,
    current_user() as created_by,
    '{{ db }}' as model_database,
    '{{ schema }}' as model_schema
from {{ input_table }}
{% endif %}

{% endmacro %}