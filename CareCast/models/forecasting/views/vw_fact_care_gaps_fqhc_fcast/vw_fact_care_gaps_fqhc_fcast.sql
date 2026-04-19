select 
    hc.fqhc_short as fqhc,
    date_trunc('month', gaps.date)::date as gap_month,
    count(distinct gaps.dim_member_key) as member_count,
    sum(total_open_care_gaps) as total_open_care_gaps,
    sum(total_closed_care_gaps) as total_closed_care_gaps,
    sum(open_care_gaps_count) as open_care_gaps_count,
    sum(closed_care_gaps_count) as closed_care_gaps_count
from {{ ref('fact_care_gaps') }} as gaps
left join {{ ref('dim_fqhc') }} as hc on gaps.dim_accountable_fqhc_key = hc.dim_fqhc_key
where gaps.dim_member_key <> -1
and gaps.date is not null
and gap_month < '2025-03-01'
group by all 
