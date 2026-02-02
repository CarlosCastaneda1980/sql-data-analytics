-- ============================================
-- Sample Data for Business Analytics
-- ============================================
-- This file contains sample data to demonstrate
-- the analytics queries
-- ============================================

-- Insert Sample Customers
INSERT INTO customers (customer_id, first_name, last_name, email, phone, city, state, country, registration_date, customer_status) VALUES
(1, 'John', 'Smith', 'john.smith@email.com', '555-0101', 'New York', 'NY', 'USA', '2023-01-15', 'active'),
(2, 'Emma', 'Johnson', 'emma.johnson@email.com', '555-0102', 'Los Angeles', 'CA', 'USA', '2023-02-20', 'active'),
(3, 'Michael', 'Williams', 'michael.williams@email.com', '555-0103', 'Chicago', 'IL', 'USA', '2023-03-10', 'active'),
(4, 'Sarah', 'Brown', 'sarah.brown@email.com', '555-0104', 'Houston', 'TX', 'USA', '2023-01-25', 'active'),
(5, 'James', 'Davis', 'james.davis@email.com', '555-0105', 'Phoenix', 'AZ', 'USA', '2023-04-05', 'active'),
(6, 'Emily', 'Miller', 'emily.miller@email.com', '555-0106', 'Philadelphia', 'PA', 'USA', '2023-05-12', 'inactive'),
(7, 'Daniel', 'Wilson', 'daniel.wilson@email.com', '555-0107', 'San Antonio', 'TX', 'USA', '2023-06-18', 'active'),
(8, 'Jessica', 'Moore', 'jessica.moore@email.com', '555-0108', 'San Diego', 'CA', 'USA', '2023-02-28', 'active'),
(9, 'David', 'Taylor', 'david.taylor@email.com', '555-0109', 'Dallas', 'TX', 'USA', '2023-07-22', 'active'),
(10, 'Ashley', 'Anderson', 'ashley.anderson@email.com', '555-0110', 'San Jose', 'CA', 'USA', '2023-08-30', 'active'),
(11, 'Christopher', 'Thomas', 'chris.thomas@email.com', '555-0111', 'Austin', 'TX', 'USA', '2023-09-15', 'inactive'),
(12, 'Amanda', 'Jackson', 'amanda.jackson@email.com', '555-0112', 'Jacksonville', 'FL', 'USA', '2023-10-05', 'active'),
(13, 'Matthew', 'White', 'matthew.white@email.com', '555-0113', 'Fort Worth', 'TX', 'USA', '2023-11-20', 'active'),
(14, 'Jennifer', 'Harris', 'jennifer.harris@email.com', '555-0114', 'Columbus', 'OH', 'USA', '2023-12-10', 'active'),
(15, 'Joshua', 'Martin', 'joshua.martin@email.com', '555-0115', 'Charlotte', 'NC', 'USA', '2024-01-08', 'active');

-- Insert Sample Orders
INSERT INTO orders (order_id, customer_id, order_date, order_amount, order_status, product_category) VALUES
-- High-value customer orders (Customer 1)
(1, 1, '2023-02-01', 1250.00, 'completed', 'Electronics'),
(2, 1, '2023-03-15', 890.50, 'completed', 'Electronics'),
(3, 1, '2023-05-20', 2100.00, 'completed', 'Appliances'),
(4, 1, '2023-07-10', 450.00, 'completed', 'Home & Garden'),
(5, 1, '2023-09-05', 1680.00, 'completed', 'Electronics'),

-- Medium-value customer orders (Customer 2)
(6, 2, '2023-03-10', 320.00, 'completed', 'Clothing'),
(7, 2, '2023-04-22', 185.50, 'completed', 'Beauty'),
(8, 2, '2023-06-15', 540.00, 'completed', 'Electronics'),
(9, 2, '2023-08-30', 275.00, 'completed', 'Clothing'),

-- High-value customer orders (Customer 3)
(10, 3, '2023-04-05', 1890.00, 'completed', 'Electronics'),
(11, 3, '2023-06-20', 2250.00, 'completed', 'Appliances'),
(12, 3, '2023-08-15', 670.00, 'completed', 'Home & Garden'),
(13, 3, '2023-10-10', 1420.00, 'completed', 'Electronics'),

-- Low-value customer orders (Customer 4)
(14, 4, '2023-02-15', 85.00, 'completed', 'Books'),
(15, 4, '2023-05-28', 120.00, 'completed', 'Beauty'),

-- Medium-value customer orders (Customer 5)
(16, 5, '2023-05-10', 450.00, 'completed', 'Electronics'),
(17, 5, '2023-07-22', 680.00, 'completed', 'Clothing'),
(18, 5, '2023-09-18', 320.00, 'completed', 'Home & Garden'),

-- Single order customers
(19, 6, '2023-06-05', 95.00, 'completed', 'Books'),
(20, 7, '2023-07-12', 1250.00, 'completed', 'Electronics'),
(21, 7, '2023-09-25', 890.00, 'completed', 'Appliances'),

-- Various order statuses
(22, 8, '2023-04-18', 560.00, 'completed', 'Electronics'),
(23, 8, '2023-08-20', 245.00, 'completed', 'Beauty'),
(24, 8, '2023-11-15', 380.00, 'cancelled', 'Clothing'),

-- Recent customers with orders
(25, 9, '2023-08-10', 720.00, 'completed', 'Electronics'),
(26, 9, '2023-10-22', 890.00, 'completed', 'Home & Garden'),
(27, 10, '2023-09-15', 1100.00, 'completed', 'Electronics'),
(28, 10, '2023-11-28', 650.00, 'completed', 'Appliances'),

-- Low activity customers
(29, 11, '2023-10-05', 145.00, 'completed', 'Books'),
(30, 12, '2023-11-10', 480.00, 'completed', 'Electronics'),
(31, 12, '2023-12-20', 325.00, 'completed', 'Beauty'),

-- Very recent customers
(32, 13, '2023-12-05', 890.00, 'completed', 'Electronics'),
(33, 14, '2024-01-15', 1250.00, 'completed', 'Appliances'),
(34, 15, '2024-02-01', 340.00, 'completed', 'Clothing');
