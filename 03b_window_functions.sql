SELECT 
    region,
    actor_name,
    incident_count,
    sophistication_tier,
    -- Multiple ranking methods for comparison
    ROW_NUMBER() OVER (PARTITION BY region ORDER BY incident_count DESC) as row_num_rank,
    RANK() OVER (PARTITION BY region ORDER BY incident_count DESC) as standard_rank,
    DENSE_RANK() OVER (PARTITION BY region ORDER BY incident_count DESC) as dense_rank,
    PERCENT_RANK() OVER (PARTITION BY region ORDER BY incident_count DESC) as percentile_rank
FROM (
    SELECT 
        ta.region,
        ta.actor_name,
        ta.sophistication_tier,
        COUNT(i.incident_id) as incident_count
    FROM threat_actors ta
    LEFT JOIN incidents i ON ta.actor_id = i.actor_id
    GROUP BY ta.region, ta.actor_name, ta.sophistication_tier
) as actor_stats
ORDER BY region, incident_count DESC;


WITH monthly_threats AS (
    SELECT 
        DATE_TRUNC('month', incident_date) as month,
        SUM(severity_score) as monthly_severity,
        COUNT(*) as incident_count
    FROM incidents
    GROUP BY DATE_TRUNC('month', incident_date)
)
SELECT 
    TO_CHAR(month, 'YYYY-MM') as month,
    incident_count,
    monthly_severity,
    SUM(monthly_severity) OVER (ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as running_severity,
    SUM(incident_count) OVER (ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as running_incidents,
    AVG(monthly_severity) OVER (ORDER BY month ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) as severity_3month_avg,
    AVG(incident_count) OVER (ORDER BY month RANGE BETWEEN INTERVAL '1' MONTH PRECEDING AND INTERVAL '1' MONTH FOLLOWING) as incidents_3month_range_avg
FROM monthly_threats
ORDER BY month;

WITH monthly_metrics AS (
    SELECT 
        DATE_TRUNC('month', incident_date) as month,
        COUNT(*) as incidents_this_month,
        SUM(severity_score) as severity_this_month
    FROM incidents
    GROUP BY DATE_TRUNC('month', incident_date)
)
SELECT 
    TO_CHAR(month, 'YYYY-MM') as month,
    incidents_this_month,
    severity_this_month,
    LAG(incidents_this_month, 1) OVER (ORDER BY month) as incidents_prev_month,
    LAG(severity_this_month, 1) OVER (ORDER BY month) as severity_prev_month,
    ROUND(
        (incidents_this_month - LAG(incidents_this_month, 1) OVER (ORDER BY month)) * 100.0 / 
        NULLIF(LAG(incidents_this_month, 1) OVER (ORDER BY month), 0), 
        1
    ) as incident_growth_pct,
    LEAD(incidents_this_month, 1) OVER (ORDER BY month) as incidents_next_month
FROM monthly_metrics
ORDER BY month;

WITH actor_severity AS (
    SELECT 
        ta.actor_id,
        ta.actor_name,
        ta.sophistication_tier,
        ta.is_state_backed,
        COUNT(i.incident_id) as total_incidents,
        SUM(i.severity_score) as total_severity,
        AVG(i.severity_score) as avg_severity
    FROM threat_actors ta
    LEFT JOIN incidents i ON ta.actor_id = i.actor_id
    GROUP BY ta.actor_id, ta.actor_name, ta.sophistication_tier, ta.is_state_backed
)
SELECT 
    actor_name,
    sophistication_tier,
    is_state_backed,
    total_incidents,
    total_severity,
    avg_severity,
    NTILE(4) OVER (ORDER BY total_severity DESC) as priority_quartile,
    CUME_DIST() OVER (ORDER BY total_severity DESC) as cumulative_distribution,
    CASE NTILE(4) OVER (ORDER BY total_severity DESC)
        WHEN 1 THEN 'TIER 1: CRITICAL'
        WHEN 2 THEN 'TIER 2: HIGH'
        WHEN 3 THEN 'TIER 3: MEDIUM'
        WHEN 4 THEN 'TIER 4: LOW'
    END as threat_level
FROM actor_severity
ORDER BY priority_quartile, total_severity DESC;

WITH daily_incidents AS (
    SELECT 
        incident_date,
        COUNT(*) as daily_count,
        SUM(severity_score) as daily_severity
    FROM incidents
    GROUP BY incident_date
),
date_series AS (
    SELECT generate_series(
        (SELECT MIN(incident_date) FROM incidents),
        (SELECT MAX(incident_date) FROM incidents),
        '1 day'::interval
    ) as date
)
SELECT 
    ds.date,
    COALESCE(di.daily_count, 0) as incidents_today,
    COALESCE(di.daily_severity, 0) as severity_today,
    AVG(COALESCE(di.daily_count, 0)) OVER (
        ORDER BY ds.date 
        ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
    ) as moving_avg_90day,
    AVG(COALESCE(di.daily_count, 0)) OVER (
        ORDER BY ds.date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as historical_avg,
    CASE 
        WHEN COALESCE(di.daily_count, 0) > 
             AVG(COALESCE(di.daily_count, 0)) OVER (
                 ORDER BY ds.date 
                 ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
             ) * 1.5
        THEN 'SPIKE DETECTED'
        ELSE 'NORMAL'
    END as anomaly_flag
FROM date_series ds
LEFT JOIN daily_incidents di ON ds.date = di.incident_date
WHERE ds.date >= (SELECT MIN(incident_date) FROM incidents)
ORDER BY ds.date;