# SQL Data Analytics

A comprehensive collection of SQL queries for business, marketing, and performance analytics using relational databases. This repository provides ready-to-use SQL queries for customer segmentation, revenue analysis, and business intelligence reporting.

## 📊 Overview

This repository contains SQL queries designed for data analysts to perform in-depth business analytics on customer and sales data. The queries are clean, well-documented, and suitable for reporting and business intelligence purposes.

## 🗂️ Repository Structure

```
sql-data-analytics/
├── schema.sql                    # Database schema with customers and orders tables
├── sample_data.sql               # Sample data for testing and demonstrations
├── customer_segmentation.sql     # Customer segmentation queries
├── revenue_analysis.sql          # Revenue analysis and performance queries
└── README.md                     # This file
```

## 📋 Database Schema

### Tables

#### Customers Table
- `customer_id` (INT, Primary Key)
- `first_name` (VARCHAR)
- `last_name` (VARCHAR)
- `email` (VARCHAR, Unique)
- `phone` (VARCHAR)
- `city` (VARCHAR)
- `state` (VARCHAR)
- `country` (VARCHAR)
- `registration_date` (DATE)
- `customer_status` (VARCHAR: 'active', 'inactive', 'suspended')

#### Orders Table
- `order_id` (INT, Primary Key)
- `customer_id` (INT, Foreign Key)
- `order_date` (DATE)
- `order_amount` (DECIMAL)
- `order_status` (VARCHAR: 'pending', 'completed', 'cancelled', 'refunded')
- `product_category` (VARCHAR)

## 🚀 Getting Started

### Prerequisites
- Any SQL database (MySQL, PostgreSQL, SQL Server, etc.)
- Database client or command-line tool

### Setup Instructions

1. **Create the database schema:**
   ```sql
   source schema.sql
   ```

2. **Load sample data (optional):**
   ```sql
   source sample_data.sql
   ```

3. **Run analytics queries:**
   ```sql
   source customer_segmentation.sql
   -- or
   source revenue_analysis.sql
   ```

## 📈 Available Queries

### Customer Segmentation Queries (`customer_segmentation.sql`)

1. **Customer Segmentation by Purchase Value**
   - Segments customers into High, Medium, and Low value tiers
   - Includes total spent, order count, and average order value

2. **Customer Segmentation by Purchase Frequency**
   - Classifies customers as Frequent, Regular, One-Time, or No Purchase
   - Useful for identifying engagement levels

3. **Customer Segmentation by Recency**
   - Segments based on last purchase date
   - Categories: Recent, Active, At Risk, Churned, Never Purchased

4. **RFM Analysis (Recency, Frequency, Monetary)**
   - Comprehensive scoring system (1-5 scale for each dimension)
   - Customer segments: Champions, Loyal Customers, Potential Loyalists, At Risk, New Customers, Lost Customers
   - Gold standard for customer segmentation in marketing

5. **Geographic Segmentation**
   - Revenue and customer distribution by location
   - Includes revenue per customer by region

6. **Product Category Preference Segmentation**
   - Identifies primary product category for each customer
   - Based on total spending in each category

### Revenue Analysis Queries (`revenue_analysis.sql`)

1. **Total Revenue by Customer Segment**
   - Revenue breakdown by High/Medium/Low value segments
   - Includes percentage contribution and customer counts

2. **Average Revenue Per Customer**
   - Overall customer lifetime value metrics
   - Average order value and orders per customer

3. **Revenue by Product Category**
   - Performance analysis by product line
   - Includes revenue percentage and order statistics

4. **Revenue Trends by Month**
   - Time-series analysis with month-over-month growth
   - Revenue change and growth percentage calculations

5. **Revenue by Customer Lifetime (Cohort Analysis)**
   - Analyzes revenue by customer registration cohort
   - Conversion rates and revenue per cohort

6. **Revenue by RFM Segment**
   - Revenue distribution across RFM customer segments
   - Percentage contributions for strategic planning

7. **Geographic Revenue Analysis**
   - Revenue performance by state and country
   - Revenue per customer and orders per customer by location

8. **Top Performing Customers**
   - Top 20 customers by total revenue
   - Lifetime metrics and estimated monthly revenue

9. **Customer Retention and Revenue Impact**
   - Month-over-month retention rates
   - Revenue impact of customer retention

## 💡 Use Cases

### Marketing
- Identify high-value customers for VIP programs
- Target at-risk customers with retention campaigns
- Personalize marketing based on product preferences
- Geographic targeting for regional campaigns

### Sales
- Focus sales efforts on high-potential segments
- Identify upsell opportunities with frequent buyers
- Analyze product category performance
- Track sales trends and seasonality

### Business Intelligence
- Executive dashboards and KPI reporting
- Revenue forecasting based on cohort analysis
- Customer lifetime value calculations
- ROI analysis for marketing campaigns

## 📊 Key Metrics Explained

### RFM Scores
- **Recency (R)**: How recently did the customer purchase?
- **Frequency (F)**: How often do they purchase?
- **Monetary (M)**: How much do they spend?

### Customer Segments
- **Champions**: Best customers (high R, F, M scores)
- **Loyal Customers**: Regular buyers with good value
- **Potential Loyalists**: Recent customers showing promise
- **At Risk**: Previously good customers who haven't purchased recently
- **New Customers**: Recent first-time buyers
- **Lost Customers**: Haven't purchased in a long time

### Revenue Metrics
- **Total Revenue**: Sum of all completed orders
- **Average Revenue Per Customer (ARPC)**: Total revenue / number of customers
- **Customer Lifetime Value (CLV)**: Total revenue from a customer over their lifetime
- **Average Order Value (AOV)**: Total revenue / number of orders

## 🔧 Customization

### Adjusting Segment Thresholds
Modify the CASE statements in the queries to adjust segment boundaries:

```sql
CASE 
    WHEN SUM(o.order_amount) >= 3000 THEN 'High Value'  -- Adjust this value
    WHEN SUM(o.order_amount) >= 1000 THEN 'Medium Value'  -- Adjust this value
    ELSE 'Low Value'
END AS customer_segment
```

### Adding Custom Dimensions
Extend the queries by adding new columns to segment customers:
- Customer demographics (age, gender)
- Acquisition channel
- Product preferences
- Payment methods

## 📝 Best Practices

1. **Data Quality**: Ensure order_status is properly set to 'completed' for accurate revenue calculations
2. **Date Ranges**: Adjust date filters based on your analysis timeframe
3. **Performance**: Indexes are defined in schema.sql for optimal query performance
4. **Regular Updates**: Run segmentation queries regularly to keep insights current
5. **A/B Testing**: Use segments for targeted experiments and measure impact

## 🤝 Contributing

Feel free to submit issues, fork the repository, and create pull requests for any improvements.

## 📄 License

This project is open source and available for educational and commercial use.

## 📞 Support

For questions or suggestions, please open an issue in this repository.

---

**Happy Analyzing! 📊**
