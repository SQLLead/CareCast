{#
    vw_actual_plus_forecast 
    
    Calls the actual_plus_forecast() macro to union historical actuals with
    post-cutoff forecast data for all enabled models in forecast_registry.

    This view requires explicit depends_on hints because the macro resolves
    source model refs dynamically at execute time from forecast_registry.input_ref.
    dbt cannot detect these as DAG dependencies at compile time.

    depends_on hints are required for:
        1.  Any model referenced by input_ref in forecast_registry (one hint per
            enabled row). Add a new hint when adding a new forecast model to the
            registry.
        2.  Any ref() inside the macro that lives within an {% if execute %} block.
            Currently that includes vw_forecast_output_latest.

    Refs that do NOT need hints:
        forecast_registry itself, because it is referenced outside the
        {% if execute %} block in the macro and dbt can see it statically.

    THE BOTTOM LINE: 
    
    QUESTION: WHEN SHOULD I ADD A NEW "depends_on" TO THIS MODEL?
    ANSWER: Whenever a new row is added to forecast_registry with a unique input_ref value.
#}

-- depends_on: {{ ref('vw_forecast_output_latest') }}
-- depends_on: {{ ref('vw_fact_care_gap_ff_fcast') }}
-- depends_on: {{ ref('vw_fact_high_utilizer_fcast') }}
-- depends_on: {{ ref('vw_fact_care_gaps_fqhc_fcast') }}

{{ actual_plus_forecast() }}
