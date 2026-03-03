{{ config(materialized='table') }}

SELECT
    customer_id,
    MIN(order_date) AS first_order,
    MAX(order_date) AS most_recent_order,
    COUNT(order_id) AS number_of_orders
FROM {{ ref('stg_orders') }}
GROUP BY customer_id