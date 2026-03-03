{{ config(materialized='table') }}

SELECT
    o.customer_id,
    SUM(p.amount) AS customer_lifetime_value
FROM {{ ref('stg_payments') }} p
JOIN {{ ref('stg_orders') }} o
    ON p.order_id = o.order_id
GROUP BY o.customer_id