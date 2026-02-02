-- Campaign Performance Analytics Queries
-- These queries help measure marketing campaign effectiveness

-- Overall campaign performance summary
SELECT 
    c.campaign_id,
    c.campaign_name,
    c.channel,
    c.budget,
    SUM(cm.impressions) AS total_impressions,
    SUM(cm.clicks) AS total_clicks,
    SUM(cm.conversions) AS total_conversions,
    SUM(cm.spend) AS total_spend,
    ROUND(SUM(cm.clicks) * 100.0 / NULLIF(SUM(cm.impressions), 0), 2) AS ctr_pct,
    ROUND(SUM(cm.conversions) * 100.0 / NULLIF(SUM(cm.clicks), 0), 2) AS conversion_rate_pct,
    ROUND(SUM(cm.spend) / NULLIF(SUM(cm.clicks), 0), 2) AS cpc,
    ROUND(SUM(cm.spend) / NULLIF(SUM(cm.conversions), 0), 2) AS cpa
FROM campaigns c
LEFT JOIN campaign_metrics cm ON c.campaign_id = cm.campaign_id
GROUP BY c.campaign_id, c.campaign_name, c.channel, c.budget
ORDER BY total_conversions DESC;

-- Campaign ROI analysis
SELECT 
    c.campaign_id,
    c.campaign_name,
    c.channel,
    SUM(cm.spend) AS total_spend,
    COUNT(DISTINCT ca.customer_id) AS customers_acquired,
    COALESCE(SUM(o.total_amount), 0) AS revenue_generated,
    COALESCE(SUM(o.total_amount), 0) - SUM(cm.spend) AS net_profit,
    ROUND((COALESCE(SUM(o.total_amount), 0) - SUM(cm.spend)) * 100.0 / NULLIF(SUM(cm.spend), 0), 2) AS roi_pct
FROM campaigns c
LEFT JOIN campaign_metrics cm ON c.campaign_id = cm.campaign_id
LEFT JOIN customer_acquisitions ca ON c.campaign_id = ca.campaign_id
LEFT JOIN orders o ON ca.customer_id = o.customer_id AND o.status = 'completed'
GROUP BY c.campaign_id, c.campaign_name, c.channel
ORDER BY roi_pct DESC;

-- Campaign performance by channel
SELECT 
    c.channel,
    COUNT(DISTINCT c.campaign_id) AS total_campaigns,
    SUM(cm.impressions) AS total_impressions,
    SUM(cm.clicks) AS total_clicks,
    SUM(cm.conversions) AS total_conversions,
    SUM(cm.spend) AS total_spend,
    ROUND(SUM(cm.clicks) * 100.0 / NULLIF(SUM(cm.impressions), 0), 2) AS avg_ctr_pct,
    ROUND(SUM(cm.conversions) * 100.0 / NULLIF(SUM(cm.clicks), 0), 2) AS avg_conversion_rate_pct,
    ROUND(SUM(cm.spend) / NULLIF(SUM(cm.clicks), 0), 2) AS avg_cpc
FROM campaigns c
LEFT JOIN campaign_metrics cm ON c.campaign_id = cm.campaign_id
GROUP BY c.channel
ORDER BY total_conversions DESC;

-- Daily campaign performance trend
SELECT 
    cm.metric_date,
    c.campaign_name,
    c.channel,
    cm.impressions,
    cm.clicks,
    cm.conversions,
    cm.spend,
    ROUND(cm.clicks * 100.0 / NULLIF(cm.impressions, 0), 2) AS ctr_pct,
    ROUND(cm.conversions * 100.0 / NULLIF(cm.clicks, 0), 2) AS conversion_rate_pct,
    ROUND(cm.spend / NULLIF(cm.clicks, 0), 2) AS cpc
FROM campaign_metrics cm
JOIN campaigns c ON cm.campaign_id = c.campaign_id
WHERE cm.metric_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
ORDER BY cm.metric_date DESC, c.campaign_name;

-- Top performing campaigns by conversion rate
SELECT 
    c.campaign_id,
    c.campaign_name,
    c.channel,
    SUM(cm.clicks) AS total_clicks,
    SUM(cm.conversions) AS total_conversions,
    ROUND(SUM(cm.conversions) * 100.0 / NULLIF(SUM(cm.clicks), 0), 2) AS conversion_rate_pct,
    ROUND(SUM(cm.spend) / NULLIF(SUM(cm.conversions), 0), 2) AS cost_per_acquisition
FROM campaigns c
JOIN campaign_metrics cm ON c.campaign_id = cm.campaign_id
GROUP BY c.campaign_id, c.campaign_name, c.channel
HAVING SUM(cm.clicks) > 100  -- Only campaigns with significant traffic
ORDER BY conversion_rate_pct DESC
LIMIT 10;

-- Campaign budget utilization
SELECT 
    c.campaign_id,
    c.campaign_name,
    c.budget,
    SUM(cm.spend) AS total_spend,
    c.budget - SUM(cm.spend) AS remaining_budget,
    ROUND(SUM(cm.spend) * 100.0 / NULLIF(c.budget, 0), 2) AS budget_utilization_pct,
    DATEDIFF(c.end_date, CURDATE()) AS days_remaining
FROM campaigns c
LEFT JOIN campaign_metrics cm ON c.campaign_id = cm.campaign_id
WHERE c.end_date >= CURDATE()
GROUP BY c.campaign_id, c.campaign_name, c.budget, c.end_date
ORDER BY budget_utilization_pct DESC;

-- Week-over-week campaign performance comparison
WITH weekly_metrics AS (
    SELECT 
        c.campaign_id,
        c.campaign_name,
        YEARWEEK(cm.metric_date) AS week,
        SUM(cm.impressions) AS impressions,
        SUM(cm.clicks) AS clicks,
        SUM(cm.conversions) AS conversions,
        SUM(cm.spend) AS spend
    FROM campaigns c
    JOIN campaign_metrics cm ON c.campaign_id = cm.campaign_id
    GROUP BY c.campaign_id, c.campaign_name, YEARWEEK(cm.metric_date)
)
SELECT 
    campaign_name,
    week,
    impressions,
    clicks,
    conversions,
    spend,
    LAG(conversions) OVER (PARTITION BY campaign_id ORDER BY week) AS prev_week_conversions,
    ROUND(((conversions - LAG(conversions) OVER (PARTITION BY campaign_id ORDER BY week)) * 100.0 / 
           NULLIF(LAG(conversions) OVER (PARTITION BY campaign_id ORDER BY week), 0)), 2) AS wow_growth_pct
FROM weekly_metrics
ORDER BY week DESC, campaign_name;
