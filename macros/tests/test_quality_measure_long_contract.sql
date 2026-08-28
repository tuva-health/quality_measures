{% test quality_measure_long_contract(model) %}

with validation as (

    select
          *
        , count(*) over (
            partition by
                  person_id
                , measure_id
                , measure_version
                , performance_period_begin
                , performance_period_end
          ) as result_row_count
    from {{ model }}

)

select *
from validation
where result_row_count != 1
   or person_id is null
   or measure_id is null
   or measure_version is null
   or performance_period_begin is null
   or performance_period_end is null
   or denominator_flag is null
   or denominator_flag != 1
   or numerator_flag is null
   or numerator_flag not in (0, 1)
   or exclusion_flag is null
   or exclusion_flag not in (0, 1)

{% endtest %}
