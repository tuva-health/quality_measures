{{ config(
     enabled = var('claims_enabled', var('clinical_enabled', False)) | as_bool
   )
}}

with diabetics_codes as (

    select distinct
          code
        , lower(code_system) as code_system
    from {{ ref('quality_measures__value_sets') }}
    where lower(concept_name) in (
          'pqa antidiabetics medications'
        )

)

, rx_diabetes as (

    select
        person_id
      , data_source
      , dispensing_date
      , ndc_code
    from {{ ref('quality_measures__stg_pharmacy_claim') }} as pharmacy_claims
    inner join diabetics_codes
        on pharmacy_claims.ndc_code = diabetics_codes.code
            and diabetics_codes.code_system = 'ndc'

)

, rx_diabetes_in_measurement_period as (

    select
          person_id
        , data_source
        , dispensing_date
    from rx_diabetes
    inner join {{ ref('quality_measures__int_supd__performance_period') }} as pp
        on dispensing_date between pp.performance_period_begin and pp.performance_period_end

)

/*
    These patients need to pass a check
    - Should have at least two distinct Date of Service (FillDate) for rx
*/

, rx_fill_order as (

    select
          person_id
        , data_source
        , dispensing_date
        , dense_rank() over (
            partition by
                  person_id
                , data_source
            order by dispensing_date
        ) as dr
    from rx_diabetes_in_measurement_period

)

, check_passed_patients as (

    select
          person_id
        , data_source
    from rx_fill_order
    where dr = 2

)

, qualifying_patients_with_age as (

    select
          patients.person_id
        , patients.data_source
        , floor({{ datediff('birth_date', 'pp.performance_period_begin', 'hour') }} / 8760.0) as age
        , performance_period_begin
        , performance_period_end
        , measure_id
        , measure_name
        , measure_version
    from {{ ref('quality_measures__stg_core__patient') }} as patients
    inner join check_passed_patients
        on patients.person_id = check_passed_patients.person_id
        and patients.data_source = check_passed_patients.data_source
    cross join {{ ref('quality_measures__int_supd__performance_period') }} as pp
    where patients.death_date is null

)

, denominator as (

    select
          person_id
        , data_source
        , age
        , performance_period_begin
        , performance_period_end
        , measure_id
        , measure_name
        , measure_version
        , 1 as denominator_flag
    from qualifying_patients_with_age
    where age > 39 and age < 76

)

, add_data_types as (

    select
          cast(person_id as {{ dbt.type_string() }}) as person_id
        , cast(data_source as {{ dbt.type_string() }}) as data_source
        , cast(age as integer) as age
        , cast(performance_period_begin as date) as performance_period_begin
        , cast(performance_period_end as date) as performance_period_end
        , cast(measure_id as {{ dbt.type_string() }}) as measure_id
        , cast(measure_name as {{ dbt.type_string() }}) as measure_name
        , cast(measure_version as {{ dbt.type_string() }}) as measure_version
        , cast(denominator_flag as {{ dbt.type_int() }}) as denominator_flag
    from denominator

)

select
      person_id
    , data_source
    , age
    , performance_period_begin
    , performance_period_end
    , measure_id
    , measure_name
    , measure_version
    , denominator_flag
    , cast('{{ var('tuva_last_run') }}' as {{ dbt.type_timestamp() }}) as tuva_last_run
from add_data_types
