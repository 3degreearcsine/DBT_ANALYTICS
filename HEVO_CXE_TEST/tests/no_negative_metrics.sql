SELECT *
FROM {{ ref('dim_customer_summary') }}
WHERE number_of_orders < 0
   OR customer_lifetime_value < 0