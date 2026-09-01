{{ config(
     enabled = var('claims_enabled', var('clinical_enabled', False)) | as_bool
   )
}}

/*
    Each measure is pivoted into a boolean column by evaluating the
    denominator, numerator, and exclusion flags.
*/
with measures_long as (

    select
          person_id
        , data_source
        , denominator_flag
        , numerator_flag
        , exclusion_flag
        , performance_flag
        , measure_id
    from {{ ref('quality_measures__summary_long') }}

)

, cqm_438 as (

    select
          person_id
        , data_source
        , performance_flag
    from measures_long
    where measure_id = 'CQM438'

)

, cqm_130 as (

    select
          person_id
        , data_source
        , performance_flag
    from measures_long
    where measure_id = 'CQM130'

)

, nqf_0420 as (

    select
          person_id
        , data_source
        , performance_flag
    from measures_long
    where measure_id = 'NQF0420'

)

, adh_diabetes as (

    select
          person_id
        , data_source
        , performance_flag
    from measures_long
    where measure_id = 'ADH-Diabetes'

)

, adh_ras as (

    select
          person_id
        , data_source
        , performance_flag
    from measures_long
    where measure_id = 'ADH-RAS'

)

, supd as (

    select
          person_id
        , data_source
        , performance_flag
    from measures_long
    where measure_id = 'SUPD'

)

, adh_statins as (

    select
          person_id
        , data_source
        , performance_flag
    from measures_long
    where measure_id = 'ADH-Statins'

)

, joined as (

    select
          measures_long.person_id
        , measures_long.data_source
        , max(cqm_438.performance_flag) as cqm_438
        , max(cqm_130.performance_flag) as cqm_130
        , max(nqf_0420.performance_flag) as nqf_0420
        , max(adh_diabetes.performance_flag) as adh_diabetes
        , max(adh_ras.performance_flag) as adh_ras
        , max(supd.performance_flag) as supd
        , max(adh_statins.performance_flag) as adh_statins
    from measures_long
        left outer join cqm_438
            on measures_long.person_id = cqm_438.person_id
            and measures_long.data_source = cqm_438.data_source
        left outer join cqm_130
            on measures_long.person_id = cqm_130.person_id
            and measures_long.data_source = cqm_130.data_source
        left outer join nqf_0420
            on measures_long.person_id = nqf_0420.person_id
            and measures_long.data_source = nqf_0420.data_source
        left outer join adh_diabetes
            on measures_long.person_id = adh_diabetes.person_id
            and measures_long.data_source = adh_diabetes.data_source
        left outer join adh_ras
            on measures_long.person_id = adh_ras.person_id
            and measures_long.data_source = adh_ras.data_source
        left outer join supd
            on measures_long.person_id = supd.person_id
            and measures_long.data_source = supd.data_source
        left outer join adh_statins
            on measures_long.person_id = adh_statins.person_id
            and measures_long.data_source = adh_statins.data_source
    group by measures_long.person_id, measures_long.data_source

)

, add_data_types as (

    select
          cast(person_id as {{ dbt.type_string() }}) as person_id
        , cast(data_source as {{ dbt.type_string() }}) as data_source
        , cast(cqm_438 as {{ dbt.type_int() }}) as cqm_438
        , cast(cqm_130 as {{ dbt.type_int() }}) as cqm_130
        , cast(nqf_0420 as {{ dbt.type_int() }}) as nqf_0420
        , cast(adh_diabetes as {{ dbt.type_int() }}) as adh_diabetes
        , cast(adh_ras as {{ dbt.type_int() }}) as adh_ras
        , cast(supd as {{ dbt.type_int() }}) as supd
        , cast(adh_statins as {{ dbt.type_int() }}) as adh_statins
    from joined

)

select
      person_id
    , data_source
    , adh_diabetes
    , adh_ras
    , adh_statins
    , cqm_130
    , cqm_438
    , nqf_0420
    , supd
    , cast('{{ var('tuva_last_run') }}' as {{ dbt.type_timestamp() }}) as tuva_last_run
from add_data_types
