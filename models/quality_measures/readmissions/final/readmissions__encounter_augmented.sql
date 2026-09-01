{{ config(
     enabled = var('claims_enabled', False) | as_bool
   )
}}

-- Here we list all encounters from the stg_encounter model
-- and we augment them with extra fields
-- that are relevant for readmission measures
select
    aa.encounter_id
    , aa.person_id
    , aa.admit_date
    , aa.discharge_date
    , aa.discharge_disposition_code
    , aa.facility_npi
    , aa.drg_code_type
    , aa.drg_code
    , aa.paid_amount
    , case
        when {{ dbt.datediff("aa.admit_date", "aa.discharge_date","day") }} = 0
        then 1
        else {{ dbt.datediff("aa.admit_date", "aa.discharge_date","day") }}
      end as length_of_stay
    , cast(case
        when bb.encounter_id is not null then 1
        else 0
      end as {{ dbt.type_int() }}) as index_admission_flag
    , cast(case
        when cc.encounter_id is not null then 1
        else 0
      end as {{ dbt.type_int() }}) as planned_flag
    , dd.specialty_cohort
    , cast(case
        when aa.discharge_disposition_code = '20' then 1
        else 0
      end as {{ dbt.type_int() }}) as died_flag
    , ee.diagnosis_ccs
    , cast(ee.disqualified_encounter_flag as {{ dbt.type_int() }}) as disqualified_encounter_flag
    , cast(ee.missing_admit_date_flag as {{ dbt.type_int() }}) as missing_admit_date_flag
    , cast(ee.missing_discharge_date_flag as {{ dbt.type_int() }}) as missing_discharge_date_flag
    , cast(ee.admit_after_discharge_flag as {{ dbt.type_int() }}) as admit_after_discharge_flag
    , cast(ee.missing_discharge_disposition_code_flag as {{ dbt.type_int() }}) as missing_discharge_disposition_code_flag
    , cast(ee.invalid_discharge_disposition_code_flag as {{ dbt.type_int() }}) as invalid_discharge_disposition_code_flag
    , cast(ee.missing_primary_diagnosis_flag as {{ dbt.type_int() }}) as missing_primary_diagnosis_flag
    , cast(ee.invalid_primary_diagnosis_code_flag as {{ dbt.type_int() }}) as invalid_primary_diagnosis_code_flag
    , cast(ee.no_diagnosis_ccs_flag as {{ dbt.type_int() }}) as no_diagnosis_ccs_flag
    , cast(ee.overlaps_with_another_encounter_flag as {{ dbt.type_int() }}) as overlaps_with_another_encounter_flag
    , cast(ee.missing_drg_flag as {{ dbt.type_int() }}) as missing_drg_flag
    , cast(ee.invalid_drg_flag as {{ dbt.type_int() }}) as invalid_drg_flag
    , aa.data_source
    , cast('{{ var('tuva_last_run') }}' as {{ dbt.type_timestamp() }}) as tuva_last_run
from
    {{ ref('readmissions__encounter') }} as aa
    left outer join {{ ref('readmissions__index_admission') }} as bb
    on aa.encounter_id = bb.encounter_id
    and aa.data_source = bb.data_source
    left outer join {{ ref('readmissions__planned_encounter') }} as cc
    on aa.encounter_id = cc.encounter_id
    and aa.data_source = cc.data_source
    left outer join {{ ref('readmissions__encounter_specialty_cohort') }} as dd
    on aa.encounter_id = dd.encounter_id
    and aa.data_source = dd.data_source
    left outer join {{ ref('readmissions__encounter_data_quality') }} as ee
    on aa.encounter_id = ee.encounter_id
    and aa.data_source = ee.data_source
