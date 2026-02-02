-- Benchmarking and Comparison Analytics Queries
-- These queries help compare performance against targets and historical data

-- Current vs previous period comparison
WITH current_period AS (
    SELECT 
        COUNT(DISTINCT order_id) AS orders,
        COUNT(DISTINCT customer_id) AS customers,
        SUM(total_amount) AS revenue,
        AVG(total_amount) AS avg_order_value
    FROM orders
    WHERE status = 'completed'
        AND order_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
),
previous_period AS (
    SELECT 
        COUNT(DISTINCT order_id) AS orders,
        COUNT(DISTINCT customer_id) AS customers,
        SUM(total_amount) AS revenue,
        AVG(total_amount) AS avg_order_value
    FROM orders
    WHERE status = 'completed'
        AND order_date >= DATE_SUB(CURDATE(), INTERVAL 60 DAY)
        AND order_date < DATE_SUB(CURDATE(), INTERVAL 30 DAY)
)
SELECT 
    'Current Period' AS period,
    cp.orders,
    cp.customers,
    cp.revenue,
    cp.avg_order_value,
    ROUND((cp.orders - pp.orders) * 100.0 / NULLIF(pp.orders, 0), 2) AS orders_change_pct,
    ROUND((cp.customers - pp.customers) * 100.0 / NULLIF(pp.customers, 0), 2) AS customers_change_pct,
    ROUND((cp.revenue - pp.revenue) * 100.0 / NULLIF(pp.revenue, 0), 2) AS revenue_change_pct
FROM current_period cp, previous_period pp
UNION ALL
SELECT 
    'Previous Period' AS period,
    pp.orders,
    pp.customers,
    pp.revenue,
    pp.avg_order_value,
    NULL AS orders_change_pct,
    NULL AS customers_change_pct,
    NULL AS revenue_change_pct
FROM previous_period pp;

-- Product category benchmark
WITH category_stats AS (
    SELECT 
        p.category,
        SUM(oi.quantity * oi.unit_price) AS revenue,
        SUM(oi.quantity) AS units_sold,
        COUNT(DISTINCT oi.order_id) AS orders
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
        AND o.order_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY p.category
),
totals AS (
    SELECT 
        SUM(revenue) AS total_revenue,
        SUM(units_sold) AS total_units,
        SUM(orders) AS total_orders
    FROM category_stats
)
SELECT 
    cs.category,
    cs.revenue,
    cs.units_sold,
    cs.orders,
    ROUND(cs.revenue * 100.0 / t.total_revenue, 2) AS revenue_share_pct,
    ROUND(cs.units_sold * 100.0 / t.total_units, 2) AS units_share_pct,
    ROUND(cs.revenue / cs.units_sold, 2) AS avg_price_per_unit
FROM category_stats cs, totals t
ORDER BY cs.revenue DESC;

-- Channel efficiency benchmark
SELECT 
    c.channel,
    COUNT(DISTINCT c.campaign_id) AS campaigns,
    SUM(cm.conversions) AS conversions,
    SUM(cm.spend) AS spend,
    ROUND(SUM(cm.spend) / NULLIF(SUM(cm.conversions), 0), 2) AS cpa,
    ROUND(SUM(cm.conversions) * 100.0 / NULLIF(SUM(cm.clicks), 0), 2) AS conversion_rate_pct,
    RANK() OVER (ORDER BY ROUND(SUM(cm.spend) / NULLIF(SUM(cm.conversions), 0), 2)) AS cpa_rank,
    RANK() OVER (ORDER BY ROUND(SUM(cm.conversions) * 100.0 / NULLIF(SUM(cm.clicks), 0), 2) DESC) AS conv_rate_rank
FROM campaigns c
LEFT JOIN campaign_metrics cm ON c.campaign_id = cm.campaign_id
WHERE cm.metric_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY c.channel
ORDER BY conversions DESC;

-- Customer segment benchmarking
WITH customer_segments AS (
    SELECT 
        customer_id,
        COUNT(order_id) AS order_count,
        SUM(total_amount) AS lifetime_value,
        CASE 
            WHEN COUNT(order_id) = 1 THEN 'One-time'
            WHEN COUNT(order_id) BETWEEN 2 AND 5 THEN 'Occasional'
            WHEN COUNT(order_id) BETWEEN 6 AND 10 THEN 'Regular'
            ELSE 'Loyal'
        END AS segment
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
)
SELECT 
    segment,
    COUNT(customer_id) AS customer_count,
    AVG(lifetime_value) AS avg_ltv,
    SUM(lifetime_value) AS total_value,
    ROUND(COUNT(customer_id) * 100.0 / (SELECT COUNT(*) FROM customer_segments), 2) AS customer_pct,
    ROUND(SUM(lifetime_value) * 100.0 / (SELECT SUM(lifetime_value) FROM customer_segments), 2) AS value_pct
FROM customer_segments
GROUP BY segment
ORDER BY 
    CASE segment
        WHEN 'Loyal' THEN 1
        WHEN 'Regular' THEN 2
        WHEN 'Occasional' THEN 3
        WHEN 'One-time' THEN 4
    END;

-- Top vs bottom performers comparison
WITH product_performance AS (
    SELECT 
        p.product_id,
        p.product_name,
        SUM(oi.quantity) AS units_sold,
        SUM(oi.quantity * oi.unit_price) AS revenue,
        RANK() OVER (ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS revenue_rank
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY p.product_id, p.product_name
)
SELECT 
    CASE 
        WHEN revenue_rank <= 5 THEN 'Top 5'
        WHEN revenue_rank > (SELECT MAX(revenue_rank) - 5 FROM product_performance) THEN 'Bottom 5'
    END AS performance_tier,
    product_name,
    units_sold,
    revenue,
    revenue_rank
FROM product_performance
WHERE revenue_rank <= 5 
   OR revenue_rank > (SELECT MAX(revenue_rank) - 5 FROM product_performance)
ORDER BY revenue_rank;

-- Conversion funnel benchmark
SELECT 
    'Visitors' AS stage,
    COUNT(DISTINCT session_id) AS count,
    100.0 AS benchmark_pct,
    100.0 AS current_pct
FROM sessions
WHERE session_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
UNION ALL
SELECT 
    'Engaged (2+ pages)' AS stage,
    COUNT(DISTINCT session_id) AS count,
    40.0 AS benchmark_pct,
    ROUND(COUNT(DISTINCT session_id) * 100.0 / (SELECT COUNT(DISTINCT session_id) FROM sessions WHERE session_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)), 2) AS current_pct
FROM sessions
WHERE session_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    AND page_views >= 2
UNION ALL
SELECT 
    'Converted' AS stage,
    COUNT(DISTINCT customer_id) AS count,
    2.5 AS benchmark_pct,
    ROUND(COUNT(DISTINCT customer_id) * 100.0 / (SELECT COUNT(DISTINCT session_id) FROM sessions WHERE session_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)), 2) AS current_pct
FROM orders
WHERE status = 'completed'
    AND order_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY);
