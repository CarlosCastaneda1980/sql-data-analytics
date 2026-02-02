-- Conversion Funnel Analytics Queries
-- These queries help analyze the customer journey and conversion process

-- Basic conversion funnel
SELECT 
    'Total Sessions' AS stage,
    COUNT(DISTINCT session_id) AS count,
    100.0 AS conversion_rate_pct
FROM sessions
UNION ALL
SELECT 
    'Sessions with Multiple Page Views' AS stage,
    COUNT(DISTINCT session_id) AS count,
    ROUND(COUNT(DISTINCT session_id) * 100.0 / (SELECT COUNT(DISTINCT session_id) FROM sessions), 2) AS conversion_rate_pct
FROM sessions
WHERE page_views > 1
UNION ALL
SELECT 
    'Customers with Orders' AS stage,
    COUNT(DISTINCT customer_id) AS count,
    ROUND(COUNT(DISTINCT customer_id) * 100.0 / (SELECT COUNT(DISTINCT session_id) FROM sessions), 2) AS conversion_rate_pct
FROM orders
WHERE status = 'completed'
UNION ALL
SELECT 
    'Repeat Customers' AS stage,
    COUNT(DISTINCT customer_id) AS count,
    ROUND(COUNT(DISTINCT customer_id) * 100.0 / (SELECT COUNT(DISTINCT session_id) FROM sessions), 2) AS conversion_rate_pct
FROM (
    SELECT customer_id
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
    HAVING COUNT(order_id) > 1
) repeat_customers;

-- Conversion rate by device type
SELECT 
    s.device_type,
    COUNT(DISTINCT s.session_id) AS total_sessions,
    COUNT(DISTINCT CASE WHEN o.order_id IS NOT NULL THEN s.customer_id END) AS converted_customers,
    ROUND(COUNT(DISTINCT CASE WHEN o.order_id IS NOT NULL THEN s.customer_id END) * 100.0 / 
          COUNT(DISTINCT s.session_id), 2) AS conversion_rate_pct
FROM sessions s
LEFT JOIN orders o ON s.customer_id = o.customer_id 
    AND DATE(o.order_date) = DATE(s.session_date)
    AND o.status = 'completed'
GROUP BY s.device_type
ORDER BY conversion_rate_pct DESC;

-- Time to conversion analysis
SELECT 
    CASE 
        WHEN days_to_purchase = 0 THEN 'Same Day'
        WHEN days_to_purchase BETWEEN 1 AND 7 THEN '1-7 Days'
        WHEN days_to_purchase BETWEEN 8 AND 30 THEN '8-30 Days'
        WHEN days_to_purchase BETWEEN 31 AND 90 THEN '31-90 Days'
        ELSE '90+ Days'
    END AS time_to_conversion,
    COUNT(DISTINCT customer_id) AS customer_count,
    AVG(first_order_value) AS avg_order_value
FROM (
    SELECT 
        c.customer_id,
        DATEDIFF(MIN(o.order_date), c.created_at) AS days_to_purchase,
        (SELECT total_amount FROM orders WHERE customer_id = c.customer_id AND status = 'completed' ORDER BY order_date LIMIT 1) AS first_order_value
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status = 'completed'
    GROUP BY c.customer_id
) conversion_time
GROUP BY time_to_conversion
ORDER BY 
    CASE time_to_conversion
        WHEN 'Same Day' THEN 1
        WHEN '1-7 Days' THEN 2
        WHEN '8-30 Days' THEN 3
        WHEN '31-90 Days' THEN 4
        ELSE 5
    END;

-- Session depth impact on conversion
SELECT 
    CASE 
        WHEN page_views = 1 THEN '1 Page'
        WHEN page_views BETWEEN 2 AND 5 THEN '2-5 Pages'
        WHEN page_views BETWEEN 6 AND 10 THEN '6-10 Pages'
        ELSE '10+ Pages'
    END AS session_depth,
    COUNT(DISTINCT s.session_id) AS total_sessions,
    COUNT(DISTINCT CASE WHEN o.order_id IS NOT NULL THEN s.session_id END) AS converted_sessions,
    ROUND(COUNT(DISTINCT CASE WHEN o.order_id IS NOT NULL THEN s.session_id END) * 100.0 / 
          COUNT(DISTINCT s.session_id), 2) AS conversion_rate_pct
FROM sessions s
LEFT JOIN orders o ON s.customer_id = o.customer_id 
    AND DATE(o.order_date) = DATE(s.session_date)
    AND o.status = 'completed'
GROUP BY session_depth
ORDER BY 
    CASE session_depth
        WHEN '1 Page' THEN 1
        WHEN '2-5 Pages' THEN 2
        WHEN '6-10 Pages' THEN 3
        ELSE 4
    END;

-- Campaign-specific conversion rates
SELECT 
    c.campaign_name,
    c.channel,
    COUNT(DISTINCT ca.customer_id) AS total_acquired,
    COUNT(DISTINCT CASE WHEN o.order_id IS NOT NULL THEN ca.customer_id END) AS customers_converted,
    ROUND(COUNT(DISTINCT CASE WHEN o.order_id IS NOT NULL THEN ca.customer_id END) * 100.0 / 
          COUNT(DISTINCT ca.customer_id), 2) AS conversion_rate_pct,
    AVG(CASE WHEN o.order_id IS NOT NULL THEN o.total_amount END) AS avg_order_value
FROM campaigns c
JOIN customer_acquisitions ca ON c.campaign_id = ca.campaign_id
LEFT JOIN orders o ON ca.customer_id = o.customer_id AND o.status = 'completed'
GROUP BY c.campaign_id, c.campaign_name, c.channel
HAVING COUNT(DISTINCT ca.customer_id) > 10
ORDER BY conversion_rate_pct DESC;

-- Drop-off analysis by stage
WITH funnel_stages AS (
    SELECT 
        1 AS stage_num, 'Visit' AS stage_name, COUNT(DISTINCT session_id) AS count
    FROM sessions
    UNION ALL
    SELECT 
        2 AS stage_num, 'Engaged (2+ pages)' AS stage_name, COUNT(DISTINCT session_id) AS count
    FROM sessions WHERE page_views >= 2
    UNION ALL
    SELECT 
        3 AS stage_num, 'Registered' AS stage_name, COUNT(DISTINCT customer_id) AS count
    FROM customers
    UNION ALL
    SELECT 
        4 AS stage_num, 'First Purchase' AS stage_name, COUNT(DISTINCT customer_id) AS count
    FROM orders WHERE status = 'completed'
)
SELECT 
    stage_name,
    count,
    LAG(count) OVER (ORDER BY stage_num) AS prev_stage_count,
    count - LAG(count) OVER (ORDER BY stage_num) AS drop_off,
    ROUND((count - LAG(count) OVER (ORDER BY stage_num)) * 100.0 / 
          NULLIF(LAG(count) OVER (ORDER BY stage_num), 0), 2) AS drop_off_rate_pct
FROM funnel_stages
ORDER BY stage_num;
