{{ config(materialized='table') }}

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    o.first_order,
    o.most_recent_order,
    COALESCE(o.number_of_orders, 0) AS number_of_orders,
    COALESCE(p.customer_lifetime_value, 0) AS customer_lifetime_value
FROM {{ ref('stg_customers') }} c
LEFT JOIN {{ ref('int_orders_agg') }} o
    ON c.customer_id = o.customer_id
LEFT JOIN {{ ref('int_payments_agg') }} p
    ON c.customer_id = p.customer_id