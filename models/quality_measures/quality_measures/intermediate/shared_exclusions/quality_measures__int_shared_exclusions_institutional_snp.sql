{{ config(
     enabled = var('claims_enabled', var('clinical_enabled', False)) | as_bool
   )
}}

/*
    patients in institutional special needs plans (snp)
    or residing in long term care

    while referencing this model, patients greater or equal than 66 years of age should be taken

    filtering out age from this model has been stripped out as different measures calculate age varingly

    future enhancement: group claims into encounters
*/

with patients as (

    select
          person_id
        , data_source
    from {{ ref('quality_measures__stg_core__patient') }}

)

, medical_claim as (

    select
          person_id
        , data_source
        , claim_start_date
        , claim_end_date
        , hcpcs_code
        , place_of_service_code
    from {{ ref('quality_measures__stg_medical_claim') }}

)

, exclusions as (

    select
          patients.person_id
        , patients.data_source
        , coalesce(
              medical_claim.claim_start_date
            , medical_claim.claim_end_date
          ) as exclusion_date
        , 'institutional or long term care' as exclusion_reason
    from patients
         inner join medical_claim
         on patients.person_id = medical_claim.person_id
         and patients.data_source = medical_claim.data_source
    where place_of_service_code in ('32', '33', '34', '54', '56')
    and {{ datediff('medical_claim.claim_start_date', 'medical_claim.claim_end_date', 'day') }} >= 90

)

select
      person_id
    , data_source
    , exclusion_date
    , exclusion_reason
    , 'institutional_snp' as exclusion_type
    , cast('{{ var('tuva_last_run') }}' as {{ dbt.type_timestamp() }}) as tuva_last_run
from exclusions
