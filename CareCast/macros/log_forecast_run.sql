{% macro log_forecast_run(
    model_name=none,
    data_source_ref=none,
    data_source_column=none,
    time_grain='monthly',
    status='completed',
    error_msg=none
) %}

{#
    Args:
        model_name: Name of the model in forecast_registry. When provided,
                   looks up input_ref and timestamp column from the registry.
        ...

    Example usage (config-driven):
        post_hook="{{ log_forecast_run(model_name=var('model_name')) }}"
#}

{% if not model_name %}
    {{ log("log_forecast_run(): skipping execution, no model_name provided.", info=true) }}
    {{ return('') }}
{% endif %}

{% if model_name %}
    {# Config-driven: look up from forecast_registry #}
    {% set config_query %}
        select * from {{ ref('forecast_registry') }}
        where lower(model_name) = lower('{{ model_name }}')
        and lower(enabled) = 'true'
    {% endset %}
    {% if execute %}
        {% set results = run_query(config_query) %}
        {% if results | length > 0 %}
            {% set row = results.rows[0] %}
            {% set resolved_data_source = data_source_ref or (this.database ~ '.' ~ this.schema ~ '.' ~ row['INPUT_REF']) %}
            {% set resolved_column = data_source_column or row['TIMESTAMP_COLNAME'] %}
        {% endif %}
    {% endif %}
    {% set model_name = model_name %}
{% else %}
    {# Convention-based: derive from this.name #}
    {% set forecast_table_name = this.name %}
    {% set view_name = 'vw_' + forecast_table_name %}
    {% set resolved_data_source = data_source_ref or (this.database ~ '.' ~ this.schema ~ '.' ~ view_name) %}
    {% set resolved_column = data_source_column or 'vb_report_month' %}
    {% set model_name = this.name + '_model' %}
{% endif %}

insert into {{ this.database }}.{{ this.schema }}.forecast_run (
    forecast_run_id,
    model_name,
    run_timestamp,
    data_as_of_month,
    forecast_name,
    status,
    rows_inserted,
    start_timestamp,
    end_timestamp,
    error_message,
    executed_by,
    forecasting_periods,
    time_grain
)
select
    '{{ invocation_id }}' as forecast_run_id,
    '{{ model_name }}' as model_name,
    current_timestamp() as run_timestamp,

    (
      select max({{ resolved_column }})::date
      from {{ resolved_data_source }}
    ) as data_as_of_month,

    '{{ this.name }}' as forecast_name,
    '{{ status }}' as status,
    (select count(*) from {{ this }}) as rows_inserted,
    '{{ run_started_at }}' as start_timestamp,
    current_timestamp() as end_timestamp,

    {% if error_msg %}
      '{{ error_msg | replace("'", "''") }}'
    {% else %}
      null
    {% endif %} as error_message,

    '{{ target.user }}' as executed_by,
    {{ var('forecast_periods', 12) }} as forecasting_periods,
    '{{ time_grain }}' as time_grain
;

{% endmacro %}
