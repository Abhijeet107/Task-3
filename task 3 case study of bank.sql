create database bank;

use bank;

select * from transactions;

select * from customer_nodes;

select * from regions;

-- How many different nodes make up the Data Bank network?
select count(distinct node_id) as unique_node
from customer_nodes;

-- How many nodes are there in each region?
SELECT r.region_name, COUNT(DISTINCT cn.node_id) AS unique_node_count
FROM customer_nodes cn
JOIN regions r ON cn.region_id = r.region_id
GROUP BY r.region_name;


-- How many customers are divided among the regions?
SELECT r.region_name, COUNT(DISTINCT cn.customer_id) AS unique_customer_count
FROM customer_nodes cn
JOIN regions r ON cn.region_id = r.region_id
GROUP BY r.region_name;

-- Determine the total amount of transactions for each region name.
SELECT r.region_name, SUM(t.txn_amount) AS total_transaction_amount
FROM customer_transactions t
JOIN customer_nodes cn ON t.customer_id = cn.customer_id
JOIN regions r ON cn.region_id = r.region_id
GROUP BY r.region_name
ORDER BY total_transaction_amount DESC;

-- How long does it take on an average to move clients to a new node?
SELECT round(avg(datediff(end_date, start_date)), 2) AS avg_days
FROM customer_nodes
WHERE end_date!='9999-12-31';

-- What is the unique count and total amount for each transaction type?
SELECT 
    txn_type,
    COUNT(DISTINCT customer_id) AS unique_transaction_count,
    SUM(txn_amount) AS total_amount
FROM 
    customer_transactions
GROUP BY 
    txn_type;
    
-- What is the average number and size of past deposits across all customers?
WITH customer_deposits AS (
    SELECT customer_id,
           COUNT(*) AS num_deposits,
           SUM(txn_amount) AS total_deposit_amount
    FROM customer_transactions
    WHERE txn_type = 'deposit'
    GROUP BY customer_id
)
SELECT 
    AVG(num_deposits) AS avg_deposits_per_customer,
    AVG(total_deposit_amount) AS avg_deposit_amount_per_customer
FROM customer_deposits;

-- For each month - how many Data Bank customers make more than 1 deposit and at least either 1 purchase or 1 withdrawal in a single month?
WITH txn_with_month AS (
    SELECT 
        customer_id,
        txn_type,
        DATE_FORMAT(txn_date, '%Y-%m') AS txn_month
    FROM customer_transactions
),
deposit_counts AS (
    SELECT 
        customer_id,
        txn_month,
        COUNT(*) AS deposit_count
    FROM txn_with_month
    WHERE txn_type = 'deposit'
    GROUP BY customer_id, txn_month
),
pw_flags AS (
    SELECT DISTINCT 
        customer_id,
        txn_month
    FROM txn_with_month
    WHERE txn_type IN ('purchase', 'withdrawal')
),
qualified_customers AS (
    SELECT d.customer_id, d.txn_month
    FROM deposit_counts d
    JOIN pw_flags p 
      ON d.customer_id = p.customer_id AND d.txn_month = p.txn_month
    WHERE d.deposit_count > 1
)
SELECT 
    txn_month,
    COUNT(DISTINCT customer_id) AS qualified_customer_count
FROM qualified_customers
GROUP BY txn_month
ORDER BY txn_month;
