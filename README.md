# SQL Data Analytics

A comprehensive collection of SQL queries for business, marketing, and performance analytics using relational databases. This repository provides ready-to-use queries for analyzing revenue, customer behavior, marketing campaigns, and operational performance.

## 📊 Overview

This repository contains production-ready SQL queries organized into three main categories:

- **Business Analytics**: Revenue tracking, customer metrics, and sales trends
- **Marketing Analytics**: Campaign performance, conversion funnels, and customer acquisition costs
- **Performance Analytics**: KPIs, operational metrics, and benchmarking

## 🗂️ Repository Structure

```
sql-data-analytics/
├── schemas/
│   └── sample_schema.sql          # Database schema for all queries
├── queries/
│   ├── business/
│   │   ├── revenue_analytics.sql   # Revenue and profitability queries
│   │   ├── customer_analytics.sql  # Customer behavior and retention
│   │   └── sales_trends.sql        # Sales patterns and trends
│   ├── marketing/
│   │   ├── campaign_performance.sql # Campaign metrics and ROI
│   │   ├── conversion_analytics.sql # Conversion funnel analysis
│   │   └── cac_analytics.sql       # Customer acquisition cost
│   └── performance/
│       ├── kpi_metrics.sql         # Key performance indicators
│       ├── operational_metrics.sql  # Operational efficiency
│       └── benchmarking.sql        # Performance comparisons
└── README.md
```

## 🚀 Getting Started

### Prerequisites

- MySQL 5.7+ or PostgreSQL 9.6+
- Basic understanding of SQL and relational databases
- Access to a database management tool (MySQL Workbench, pgAdmin, etc.)

### Setup

1. **Create the database schema**:
   ```sql
   -- Run the schema file to create tables
   SOURCE schemas/sample_schema.sql;
   ```

2. **Populate with your data** or use sample data for testing

3. **Run queries** from the relevant category folder

## 📈 Query Categories

### Business Analytics

#### Revenue Analytics
- **Total revenue by month**: Track monthly revenue trends
- **Revenue by product category**: Identify top-performing categories
- **Top revenue-generating customers**: Find your most valuable customers
- **Revenue growth rate**: Calculate month-over-month growth
- **Product profitability**: Analyze profit margins by product

#### Customer Analytics
- **Customer cohort analysis**: Track customer groups over time
- **Customer retention**: Measure repeat purchase rates
- **Customer segmentation**: Group customers by behavior
- **Churn analysis**: Identify at-risk customers
- **Customer lifetime value**: Calculate LTV by acquisition source

#### Sales Trends
- **Year-over-year comparison**: Compare sales across years
- **Sales by day/hour**: Identify peak selling times
- **Moving averages**: Smooth out sales fluctuations
- **Seasonal patterns**: Understand quarterly trends
- **Product performance**: Track best and worst sellers

### Marketing Analytics

#### Campaign Performance
- **Campaign ROI**: Measure return on marketing investment
- **Channel comparison**: Compare effectiveness across channels
- **Cost metrics**: Track CPC, CPA, and CTR
- **Budget utilization**: Monitor campaign spending
- **Performance trends**: Track campaign improvements

#### Conversion Analytics
- **Conversion funnel**: Visualize customer journey stages
- **Drop-off analysis**: Identify where customers leave
- **Time to conversion**: Measure purchase decision time
- **Device performance**: Compare conversion rates by device
- **Campaign-specific conversions**: Track campaign effectiveness

#### CAC Analytics
- **Customer acquisition cost**: Calculate cost per customer
- **LTV to CAC ratio**: Measure acquisition efficiency
- **Payback period**: Calculate time to recover CAC
- **CAC trends**: Monitor acquisition costs over time
- **Channel efficiency**: Compare CAC across channels

### Performance Analytics

#### KPI Metrics
- **Daily dashboard**: Track key metrics daily
- **Monthly summary**: Aggregate monthly performance
- **Product KPIs**: Monitor product-level metrics
- **Customer health**: Score customer engagement
- **Growth metrics**: Calculate growth rates

#### Operational Metrics
- **Order fulfillment**: Track completion rates
- **Website performance**: Monitor session metrics
- **Device breakdown**: Analyze traffic by device
- **Peak traffic**: Identify high-load periods
- **Cart abandonment**: Track checkout drop-offs

#### Benchmarking
- **Period comparisons**: Compare current vs previous periods
- **Category benchmarks**: Rank product categories
- **Channel efficiency**: Compare marketing channels
- **Segment analysis**: Benchmark customer segments
- **Performance tiers**: Identify top and bottom performers

## 💡 Usage Examples

### Example 1: Monthly Revenue Report
```sql
-- From queries/business/revenue_analytics.sql
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_order_value
FROM orders
WHERE status = 'completed'
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month DESC;
```

### Example 2: Campaign ROI Analysis
```sql
-- From queries/marketing/campaign_performance.sql
SELECT 
    c.campaign_name,
    SUM(cm.spend) AS total_spend,
    SUM(o.total_amount) AS revenue_generated,
    ROUND((SUM(o.total_amount) - SUM(cm.spend)) * 100.0 / SUM(cm.spend), 2) AS roi_pct
FROM campaigns c
LEFT JOIN campaign_metrics cm ON c.campaign_id = cm.campaign_id
LEFT JOIN customer_acquisitions ca ON c.campaign_id = ca.campaign_id
LEFT JOIN orders o ON ca.customer_id = o.customer_id
WHERE o.status = 'completed'
GROUP BY c.campaign_id, c.campaign_name
ORDER BY roi_pct DESC;
```

## 🔧 Customization

All queries can be customized to fit your specific needs:

1. **Date ranges**: Adjust `DATE_SUB()` functions for different time periods
2. **Thresholds**: Modify numeric conditions for segmentation
3. **Metrics**: Add or remove columns based on your requirements
4. **Joins**: Adapt table relationships to your schema
5. **Filters**: Add WHERE clauses for specific analysis

## 📊 Database Schema

The sample schema includes the following tables:

- `customers`: Customer information and registration dates
- `products`: Product catalog with pricing and categories
- `orders`: Order transactions and status
- `order_items`: Line items for each order
- `campaigns`: Marketing campaign details
- `campaign_metrics`: Daily campaign performance data
- `customer_acquisitions`: Customer attribution to campaigns
- `sessions`: Website visitor sessions

See `schemas/sample_schema.sql` for the complete schema definition.

## 🎯 Best Practices

1. **Index optimization**: Ensure proper indexes on date and foreign key columns
2. **Performance**: Test queries on sample data before running on production
3. **Parameterization**: Use variables for date ranges and thresholds
4. **Documentation**: Comment your customizations for team reference
5. **Version control**: Track query modifications for reproducibility

## 📝 Query Syntax

All queries are written for MySQL but can be easily adapted for:

- **PostgreSQL**: Replace `DATE_FORMAT()` with `TO_CHAR()`
- **SQL Server**: Use `FORMAT()` instead of `DATE_FORMAT()`
- **Oracle**: Adjust date functions to Oracle syntax

## 🤝 Contributing

Contributions are welcome! To add new queries:

1. Follow the existing query structure and naming conventions
2. Include comments explaining the query purpose
3. Test queries with sample data
4. Document any specific requirements or assumptions

## 📄 License

This project is open source and available for use in your analytics projects.

## 🔗 Related Resources

- [SQL Style Guide](https://www.sqlstyle.guide/)
- [MySQL Documentation](https://dev.mysql.com/doc/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

## ⚡ Quick Reference

### Common Time Ranges
- Last 30 days: `WHERE order_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)`
- Last 3 months: `WHERE order_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)`
- Current year: `WHERE YEAR(order_date) = YEAR(CURDATE())`

### Common Aggregations
- Total: `SUM(amount)`
- Average: `AVG(amount)`
- Count: `COUNT(DISTINCT id)`
- Growth: `(current - previous) / previous * 100`

### Common Joins
```sql
-- Customer orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id

-- Order items with products
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id

-- Campaign attribution
FROM campaigns c
JOIN customer_acquisitions ca ON c.campaign_id = ca.campaign_id
```

---

**Note**: This repository provides query templates. Adjust table names, column names, and business logic to match your specific database schema and requirements.
