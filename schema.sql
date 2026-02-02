-- ============================================
-- Database Schema for Business Analytics
-- ============================================
-- This schema defines the core tables for analyzing
-- customer behavior and sales performance
-- ============================================

-- Customers Table
-- Stores customer information including contact details and registration date
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    city VARCHAR(50),
    state VARCHAR(50),
    country VARCHAR(50),
    registration_date DATE NOT NULL,
    customer_status VARCHAR(20) DEFAULT 'active' CHECK (customer_status IN ('active', 'inactive', 'suspended'))
);

-- Orders Table
-- Tracks all customer orders including amount, date, and status
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    order_amount DECIMAL(10, 2) NOT NULL,
    order_status VARCHAR(20) DEFAULT 'pending' CHECK (order_status IN ('pending', 'completed', 'cancelled', 'refunded')),
    product_category VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Indexes for better query performance
CREATE INDEX idx_customers_registration ON customers(registration_date);
CREATE INDEX idx_customers_status ON customers(customer_status);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_orders_status ON orders(order_status);
CREATE INDEX idx_orders_category ON orders(product_category);
