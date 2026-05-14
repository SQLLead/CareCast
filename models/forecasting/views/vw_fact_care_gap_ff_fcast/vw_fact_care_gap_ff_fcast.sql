-- Training input view for the care gap forward-fill forecast.
-- Aggregates fact_care_gap_ff to distinct member counts per health plan per VB report month.

select
    vb_report_month,
    health_plan,
    count(distinct dim_member_key) as member_count
from {{ ref('fact_care_gap_ff') }}
group by vb_report_month, health_plan
