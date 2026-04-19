{{ config(tags=['forecast']) }}

-- training input view for the high utilizer forward-fill forecast.
-- aggregates fact_high_utilizer to monthly utilization measure totals per health center.

select
    date_trunc('month', fhu.visit_date) as visit_month,
    df.fqhc,
    sum(fhu.total_ed_visits) as total_ed_visits,
    sum(fhu.total_avoidable_ed_visits) as total_avoidable_ed_visits,
    sum(fhu.total_ip_stays) as total_ip_stays,
    sum(fhu.total_readmissions) as total_readmissions
from {{ ref('fact_high_utilizer') }} as fhu
left join {{ ref('dim_fqhc') }} as df on fhu.dim_fqhc_key = df.dim_fqhc_key
where visit_date is not null
group by 1, 2