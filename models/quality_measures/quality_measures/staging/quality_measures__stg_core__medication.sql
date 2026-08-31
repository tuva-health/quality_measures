{{ config(
     enabled = var('claims_enabled', var('clinical_enabled', False)) | as_bool
   )
}}

{% if var('clinical_enabled', False) == true and var('claims_enabled', False) == true -%}

select
      person_id
    , data_source
    , encounter_id
    , prescribing_date
    , dispensing_date
    , source_code_type
    , source_code
    , ndc_code
    , rxnorm_code
    , cast('{{ var('tuva_last_run') }}' as {{ dbt.type_timestamp() }}) as tuva_last_run
from {{ ref('core__medication') }}

{% elif var('clinical_enabled', False) == true -%}

select
      person_id
    , data_source
    , encounter_id
    , prescribing_date   
    , dispensing_date
    , source_code_type
    , source_code
    , ndc_code
    , rxnorm_code
    , cast('{{ var('tuva_last_run') }}' as {{ dbt.type_timestamp() }}) as tuva_last_run
from {{ ref('core__medication') }}

{% elif var('claims_enabled', False) == true -%}

{% if target.type == 'fabric' %}
    select top 0
          cast(null as {{ dbt.type_string() }} ) as person_id
        , cast(null as {{ dbt.type_string() }} ) as data_source
        , cast(null as {{ dbt.type_string() }} ) as encounter_id
        , {{ the_tuva_project.try_to_cast_date('null', 'YYYY-MM-DD') }} as prescribing_date
        , {{ the_tuva_project.try_to_cast_date('null', 'YYYY-MM-DD') }} as dispensing_date
        , cast(null as {{ dbt.type_string() }} ) as source_code_type
        , cast(null as {{ dbt.type_string() }} ) as source_code
        , cast(null as {{ dbt.type_string() }} ) as ndc_code
        , cast(null as {{ dbt.type_string() }} ) as rxnorm_code
        , cast(null as {{ dbt.type_timestamp() }} ) as tuva_last_run
{% else %}
select
          cast(null as {{ dbt.type_string() }} ) as person_id
        , cast(null as {{ dbt.type_string() }} ) as data_source
        , cast(null as {{ dbt.type_string() }} ) as encounter_id
        , {{ the_tuva_project.try_to_cast_date('null', 'YYYY-MM-DD') }} as prescribing_date
        , {{ the_tuva_project.try_to_cast_date('null', 'YYYY-MM-DD') }} as dispensing_date
        , cast(null as {{ dbt.type_string() }} ) as source_code_type
        , cast(null as {{ dbt.type_string() }} ) as source_code
        , cast(null as {{ dbt.type_string() }} ) as ndc_code
        , cast(null as {{ dbt.type_string() }} ) as rxnorm_code
        , cast(null as {{ dbt.type_timestamp() }} ) as tuva_last_run
    limit 0
{%- endif %}

{%- endif %}
