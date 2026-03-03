{{ config(materialized='view') }}

SELECT
    id AS payment_id,
    order_id,
    amount
FROM {{ source('raw', 'raw_payments') }}