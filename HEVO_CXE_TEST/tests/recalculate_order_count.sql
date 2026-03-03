WITH recalculated AS (
    SELECT
        customer_id,
        COUNT(*) AS actual_orders
    FROM {{ ref('stg_orders') }}
    GROUP BY customer_id
)

SELECT s.*
FROM {{ ref('dim_customer_summary') }} s
JOIN recalculated r
    ON s.customer_id = r.customer_id
WHERE s.number_of_orders != r.actual_orders