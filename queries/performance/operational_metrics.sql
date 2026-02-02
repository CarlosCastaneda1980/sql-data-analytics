-- Operational Performance Analytics Queries
-- These queries help monitor operational efficiency and system health

-- Order fulfillment metrics
SELECT 
    DATE(order_date) AS order_day,
    COUNT(order_id) AS total_orders,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) AS completed_orders,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) AS pending_orders,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) AS cancelled_orders,
    ROUND(COUNT(CASE WHEN status = 'completed' THEN 1 END) * 100.0 / COUNT(order_id), 2) AS fulfillment_rate_pct,
    ROUND(COUNT(CASE WHEN status = 'cancelled' THEN 1 END) * 100.0 / COUNT(order_id), 2) AS cancellation_rate_pct
FROM orders
WHERE order_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY DATE(order_date)
ORDER BY order_day DESC;

-- Website performance metrics
SELECT 
    DATE(session_date) AS visit_date,
    COUNT(DISTINCT session_id) AS total_sessions,
    COUNT(DISTINCT customer_id) AS unique_visitors,
    SUM(page_views) AS total_page_views,
    AVG(page_views) AS avg_pages_per_session,
    AVG(duration_seconds) AS avg_session_duration_sec,
    ROUND(AVG(duration_seconds) / 60.0, 2) AS avg_session_duration_min,
    COUNT(CASE WHEN page_views = 1 THEN 1 END) AS bounce_sessions,
    ROUND(COUNT(CASE WHEN page_views = 1 THEN 1 END) * 100.0 / COUNT(session_id), 2) AS bounce_rate_pct
FROM sessions
WHERE session_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY DATE(session_date)
ORDER BY visit_date DESC;

-- Device performance breakdown
SELECT 
    device_type,
    COUNT(DISTINCT session_id) AS total_sessions,
    AVG(page_views) AS avg_pages_per_session,
    AVG(duration_seconds) AS avg_duration_seconds,
    COUNT(DISTINCT customer_id) AS unique_users,
    ROUND(COUNT(session_id) * 100.0 / (SELECT COUNT(*) FROM sessions WHERE session_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)), 2) AS session_share_pct
FROM sessions
WHERE session_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY device_type
ORDER BY total_sessions DESC;

-- Order size distribution
SELECT 
    CASE 
        WHEN total_amount < 50 THEN 'Under $50'
        WHEN total_amount BETWEEN 50 AND 100 THEN '$50-$100'
        WHEN total_amount BETWEEN 100 AND 200 THEN '$100-$200'
        WHEN total_amount BETWEEN 200 AND 500 THEN '$200-$500'
        ELSE 'Over $500'
    END AS order_value_range,
    COUNT(order_id) AS order_count,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_order_value,
    ROUND(COUNT(order_id) * 100.0 / (SELECT COUNT(*) FROM orders WHERE status = 'completed'), 2) AS pct_of_orders
FROM orders
WHERE status = 'completed'
GROUP BY order_value_range
ORDER BY 
    CASE order_value_range
        WHEN 'Under $50' THEN 1
        WHEN '$50-$100' THEN 2
        WHEN '$100-$200' THEN 3
        WHEN '$200-$500' THEN 4
        ELSE 5
    END;

-- Peak traffic hours
SELECT 
    HOUR(session_date) AS hour_of_day,
    COUNT(session_id) AS session_count,
    AVG(page_views) AS avg_pages_per_session,
    COUNT(DISTINCT customer_id) AS unique_visitors,
    ROUND(COUNT(session_id) * 100.0 / (SELECT COUNT(*) FROM sessions WHERE session_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)), 2) AS pct_of_traffic
FROM sessions
WHERE session_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY HOUR(session_date)
ORDER BY hour_of_day;

-- Cart abandonment analysis (simulated)
WITH sessions_with_items AS (
    SELECT 
        s.session_id,
        s.customer_id,
        s.session_date,
        COUNT(DISTINCT oi.product_id) AS items_viewed
    FROM sessions s
    LEFT JOIN orders o ON s.customer_id = o.customer_id 
        AND DATE(o.order_date) = DATE(s.session_date)
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    WHERE s.page_views > 2
    GROUP BY s.session_id, s.customer_id, s.session_date
)
SELECT 
    DATE(session_date) AS visit_date,
    COUNT(DISTINCT session_id) AS engaged_sessions,
    COUNT(DISTINCT CASE WHEN items_viewed > 0 THEN session_id END) AS sessions_with_orders,
    COUNT(DISTINCT CASE WHEN items_viewed = 0 THEN session_id END) AS abandoned_sessions,
    ROUND(COUNT(DISTINCT CASE WHEN items_viewed = 0 THEN session_id END) * 100.0 / 
          COUNT(DISTINCT session_id), 2) AS abandonment_rate_pct
FROM sessions_with_items
GROUP BY DATE(session_date)
ORDER BY visit_date DESC;

-- System load by day of week
SELECT 
    DAYNAME(session_date) AS day_of_week,
    DAYOFWEEK(session_date) AS day_num,
    COUNT(session_id) AS total_sessions,
    AVG(page_views) AS avg_pages_per_session,
    SUM(page_views) AS total_page_views,
    COUNT(DISTINCT customer_id) AS unique_visitors
FROM sessions
WHERE session_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY DAYNAME(session_date), DAYOFWEEK(session_date)
ORDER BY day_num;

-- Customer service workload (based on order volume)
SELECT 
    DATE(order_date) AS order_date,
    COUNT(order_id) AS total_orders,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) AS orders_needing_processing,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) AS cancellations,
    ROUND(AVG(total_amount), 2) AS avg_order_value,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM orders
WHERE order_date >= DATE_SUB(CURDATE(), INTERVAL 14 DAY)
GROUP BY DATE(order_date)
ORDER BY order_date DESC;
