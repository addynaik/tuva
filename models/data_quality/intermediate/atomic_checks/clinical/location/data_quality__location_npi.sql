{{ config(
    enabled = var('clinical_enabled', False)
) }}


SELECT
      m.data_source
    {% if target.type == 'bigquery' %}
        , cast(coalesce({{ dbt.current_timestamp() }}, cast('1900-01-01' as timestamp)) as date) as source_date
    {%- else -%}
        , cast(coalesce({{ dbt.current_timestamp() }}, cast('1900-01-01' as date)) as date) as source_date
    {% endif %}
    , 'LOCATION' AS table_name
    , 'Location ID' as drill_down_key
    , coalesce(location_id, 'NULL') AS drill_down_value
    , 'NPI' as field_name
    , case when term.npi is not null then 'valid'
          when m.npi is not null then 'invalid'
          else 'null'
    end as bucket_name
    , case when m.npi is not null and term.npi is null
          then 'NPI does not join to Terminology provider table'
    else null end as invalid_reason
    , cast(m.npi as {{ dbt.type_string() }}) as field_value
    , '{{ var('tuva_last_run')}}' as tuva_last_run
from {{ ref('location')}} m
left join {{ ref('terminology__provider')}} term on m.npi = term.npi
