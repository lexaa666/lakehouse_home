CREATE SCHEMA IF NOT EXISTS iceberg.cortex;




CREATE TABLE IF NOT EXISTS iceberg.cortex.transactions (
    transaction_id VARCHAR,
    client_id VARCHAR,
    transaction_date TIMESTAMP,
    amount DOUBLE,
    currency VARCHAR,
    merchant_id VARCHAR,
    payment_method VARCHAR,
    status VARCHAR,
    category VARCHAR,
    notes VARCHAR
)
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['day(transaction_date)'],
    location = 's3a://lakehouse/cortex/transactions'
);




select * from iceberg.cortex.transactions;

--where  date(transaction_date) = DATE '2025-04-10';






INSERT into  iceberg.cortex.transactions
WITH dates AS (
    SELECT sequence(date('2024-01-01'), date('2024-01-02'), interval '1' day) AS date_seq
),
expanded_dates AS (
    SELECT date_value
    FROM dates
    CROSS JOIN UNNEST(date_seq) AS t(date_value)
),
transactions AS (
    SELECT
        CAST(uuid() AS varchar) AS transaction_id,
        CAST(concat('client_', CAST(CAST(rand() * 1000 AS integer) AS varchar)) AS varchar) AS client_id,
        CAST(cast(date_value AS timestamp(6)) + (CAST(rand() * 86400 AS integer) * interval '1' second) AS timestamp(6)) AS transaction_date,
        CAST(round(rand() * 1000, 2) AS double) AS amount,
        CAST(CASE CAST(rand() * 4 AS integer)
            WHEN 0 THEN 'USD'
            WHEN 1 THEN 'EUR'
            WHEN 2 THEN 'GBP'
            ELSE 'JPY'
        END AS varchar) AS currency,
        CAST(concat('merchant_', CAST(CAST(rand() * 100 AS integer) AS varchar)) AS varchar) AS merchant_id,
        CAST(CASE CAST(rand() * 3 AS integer)
            WHEN 0 THEN 'card'
            WHEN 1 THEN 'cash'
            ELSE 'online'
        END AS varchar) AS payment_method,
        CAST(CASE CAST(rand() * 2 AS integer)
            WHEN 0 THEN 'completed'
            ELSE 'pending'
        END AS varchar) AS status,
        CAST(CASE CAST(rand() * 5 AS integer)
            WHEN 0 THEN 'food'
            WHEN 1 THEN 'electronics'
            WHEN 2 THEN 'clothing'
            WHEN 3 THEN 'health'
            ELSE 'other'
        END AS varchar) AS category,
        CAST('Generated transaction' AS varchar) AS notes
    FROM expanded_dates
    CROSS JOIN UNNEST(sequence(1, 10000)) AS t(i)
)
SELECT * FROM transactions;




CREATE TABLE IF NOT EXISTS iceberg.cortex.clients (
    client_id VARCHAR,
    first_name VARCHAR,
    last_name VARCHAR,
    email VARCHAR,
    phone_number VARCHAR,
    registration_date TIMESTAMP,
    status VARCHAR
)
WITH (
    format = 'PARQUET',
    location = 's3a://lakehouse/cortex/clients'
);


insert
	into
	iceberg.cortex.clients
select
	cast(concat('client_', cast(cast(rand() * 1000 as INTEGER) as VARCHAR)) as VARCHAR) as client_id,
	element_at(
        array['Alice', 'Bob', 'Charlie', 'Diana', 'Eve', 'Frank'],
        cast(rand() * 6 + 1 as INTEGER)
    ) as first_name,
	element_at(
        array['Smith', 'Johnson', 'Brown', 'Taylor', 'Anderson', 'Clark'],
        cast(rand() * 6 + 1 as INTEGER)
    ) as last_name,
	concat(
        'user',
        cast(cast(rand() * 100000 as INTEGER) as VARCHAR),
        '@example.com'
    ) as email,
	concat(
        '+1',
        cast(1000000000 + cast(rand() * 8999999999 as BIGINT) as VARCHAR)
    ) as phone_number,
	current_date - interval '1' day * cast(rand() * 365 as INTEGER) as registration_date,
	element_at(
        array['active', 'inactive', 'suspended'],
        cast(rand() * 3 + 1 as INTEGER)
    ) as status
from
	unnest(sequence(1, 10000)) as t(x);


select
	*
from
	iceberg.cortex.transactions t1
join iceberg.cortex.clients t2 on
	t1.client_id= t2.client_id ;