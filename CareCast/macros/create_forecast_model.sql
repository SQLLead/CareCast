{% macro create_forecast_model(model_name) %}

{#
    Creates a Snowflake ML forecast model.
    Looks up model configuration from the forecast_registry seed.

    Args:
        model_name: Name of the model as defined in forecast_registry seed.

    Usage (as pre_hook):
        pre_hook="{{ create_forecast_model(var('model_name')) }}"
#}

{% if not model_name %}
    {{ log("create_forecast_model(): skipping execution, no model_name provided.", info=true) }}
    {{ return('') }}
{% endif %}

{% set config_query %}
    select * from {{ ref('forecast_registry') }}
    where lower(model_name) = lower('{{ model_name }}')
    and enabled::boolean = true
{% endset %}

{% if execute %}
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
    {% set input_table = db ~ '.' ~ schema ~ '.' ~ row['INPUT_REF'] %}
    {% set series_col = row['SERIES_COLNAME'] %}
    {% set ts_col = row['TIMESTAMP_COLNAME'] %}
    {% set target_col = row['TARGET_COLNAME'] %}

    {#
        Create a scoped view containing only the columns Snowflake ML needs.
        Any extra columns in the input view would be silently treated as exogenous
        features, breaking the !FORECAST(forecasting_periods => N) call.
    #}
    {% set scoped_view = db ~ '.' ~ schema ~ '.' ~ model_name ~ '_training_scoped' %}
    {% set create_scoped_view %}
        CREATE OR REPLACE VIEW {{ scoped_view }} AS
        SELECT {{ series_col }}, {{ ts_col }}, {{ target_col }}
        FROM {{ input_table }}
    {% endset %}
    {% do run_query(create_scoped_view) %}

CREATE OR REPLACE SNOWFLAKE.ML.FORECAST {{ model_fqn }} (
    INPUT_DATA => SYSTEM$REFERENCE('VIEW', '{{ scoped_view }}'),
    SERIES_COLNAME => '{{ series_col }}',
    TIMESTAMP_COLNAME => '{{ ts_col }}',
    TARGET_COLNAME => '{{ target_col }}'
)
{% endif %}

{% endmacro %}
