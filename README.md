# DBT Analytics Project

## 📌 Project Overview

This project demonstrates an end-to-end analytics engineering workflow using dbt, starting from raw ingestion to a fully tested customer-level mart model.

The objective was to:

* Ingest raw data via an ETL pipeline
* Transform it using layered dbt models
* Implement data quality validations
* Debug real-world NULL propagation issues
* Maintain production-grade project structure and version control

The final output is a dimensional model centered around `dim_customer_summary`, built using a clean staging → intermediate → marts architecture.

---

## 🏗 Architecture Overview

<img width="1132" height="355" alt="DAG" src="https://github.com/user-attachments/assets/03607393-8b2d-4011-8ace-f75c7c6482e0" />

The project follows a three-layer modeling approach:

### 1️⃣ Staging Layer (`stg_` models)

* Renamed and standardized columns

* Removed unnecessary fields

* Preserved source grain

Sources defined:

* raw_customers
* raw_orders
* raw_payments

### 2️⃣ Intermediate Layer (`int_` models)

* Performed aggregations at customer grain

Examples:

* `int_orders_agg` → first_order, most_recent_order, number_of_orders
* `int_payments_agg` → customer_lifetime_value

Important observation:
There were no NULL values generated during the aggregation stage. Aggregations were logically correct and returned valid results for existing rows.

### 3️⃣ Mart Layer (`dim_` models)

* One row per customer
* LEFT JOINs from staging to intermediate aggregates
* Applied final business-safe defaults

Final Model:

* `dim_customer_summary`

---

## 📊 NULL Propagation Issue & Resolution

Although aggregation models were correct, NULL values appeared in the marts layer.

### Root Cause

When creating one row per customer using LEFT JOINs, customers without matching records in intermediate models resulted in NULL values for:

* number_of_orders
* customer_lifetime_value

This was not an aggregation issue.
It was a dimensional modeling issue caused by row expansion at the customer grain.

### Resolution

Applied COALESCE in the final mart model:

* `COALESCE(o.number_of_orders, 0)`
* `COALESCE(p.customer_lifetime_value, 0)`

This ensured:

* Passing `not_null` tests
* Correct semantic meaning for customers without orders

Only the marts SQL logic required modification.

---

## ✅ Data Quality & Validation Strategy

### Implemented Tests

* not_null on primary identifiers
* unique on customer_id
* relationships for referential integrity
* not_null on aggregated metrics

Validation outputs are available via:

* Terminal logs
* Test Output
<img width="1151" height="685" alt="Test 1" src="https://github.com/user-attachments/assets/58367f81-fe70-419c-860a-fc80120f18a0" />
<img width="1176" height="706" alt="Test 2" src="https://github.com/user-attachments/assets/3378cc20-56ca-447c-8428-82a22a68b71f" />

### Important Observation: `test` vs `build`

Since `dbt build` is the modern orchestration command, I deliberately validated how it differs from running `dbt run` and `dbt test` separately.

* `dbt test` → Runs only explicitly defined tests
* `dbt build` → Runs models + tests + dependency checks in DAG order

Through experimentation, I confirmed that `build` ensures model creation before testing and enforces dependency validation in a single execution flow.

<img width="1167" height="236" alt="Build Test 1" src="https://github.com/user-attachments/assets/8fe785f4-c736-445e-813a-bacb62166cd0" />
<img width="1147" height="125" alt="Build Test 2" src="https://github.com/user-attachments/assets/51027292-9cf2-46bf-b220-1bb5ce109dc8" />

Test Output screenshots of both 'test' and 'build' commands are included to demonstrate this comparison. 'build' auto-tested tables and Views creation.

---

## ⚙️ Infrastructure & ETL Setup

### Initial Attempt

* Tried local Docker PostgreSQL setup
* ETL successfully connected
* Objects were detected in UI
* However, UI reported SELECT privilege errors

Even though SELECT privileges were granted already, the UI showed permission issues.

Screenshots of:

* Granted privileges
  <img width="1182" height="538" alt="Privileges 1" src="https://github.com/user-attachments/assets/25dfcfe0-bc4e-42aa-9739-962d81676543" />
  <img width="1126" height="187" alt="Privileges 2" src="https://github.com/user-attachments/assets/58b6daba-536e-4720-9d3f-6f605114109a" />

* ETL error message
  <img width="1646" height="828" alt="ETL Error" src="https://github.com/user-attachments/assets/457e58b9-d6ab-43ce-8704-a30834996f6a" />

### Final Approach

* Created Cloud Compute VM instance
* Configured firewall rules to allow required inbound traffic (PostgreSQL port 5432) from ETL source IP
* Ensured secure access by restricting public exposure and allowing only necessary IP addresses
* Deployed PostgreSQL using Docker image
* Connected ETL pipeline from Hevo
* Successfully ingested raw data

Configuring firewall rules was a critical step. Without explicitly allowing inbound traffic on port 5432, the ETL service could not establish a stable connection to the VM-hosted PostgreSQL instance.

This cloud-based Docker setup, along with proper firewall configuration, resolved object visibility and connectivity inconsistencies experienced in the local environment.

---

## 🔐 Configuration & profiles.yml Issue

During setup, the auto-generated `profiles.yml` did not include the required `user` field.

This caused the error:

"Invalid profile: 'user' is a required property"

Resolution:

* Manually added the required `user` field

### Improvement

`profiles.yml` is excluded from version control via `.gitignore` to avoid exposing credentials.

---

## 🧠 Assumptions

1. Every customer must appear in the final dimension.
2. Customers without orders should:
   * Have number_of_orders = 0
   * Have customer_lifetime_value = 0
3. Aggregations are computed at customer grain.
4. Raw data structure is valid but requires transformation for analytics use.

---

## 📈 Challenges Encountered

1. NULL propagation due to LEFT JOIN at mart layer
2. Deep dive into understanding differences between `test` and `build` behavior (intentional exploration of modern dbt workflow)
3. profiles.yml missing required properties
4. Local Docker PostgreSQL object visibility inconsistencies

Each issue was resolved through systematic debugging and validation.

---

## 🚀 How to Run Locally

1. Create `profiles.yml` with required Snowflake fields
2. Run:

```bash
dbt debug
dbt build
```

3. Review:

* DAG graph
* Test results
* Artifacts in `target/`

---

## 🎯 Key Learning Outcomes

* Layered modeling best practices
* Understanding NULL propagation across joins
* Test-driven transformation development
* Differences between compile, run, test, and build
* Infrastructure debugging across Docker and cloud environments
* Git hygiene and configuration separation

---

This project demonstrates not just SQL modeling, but full-stack analytics engineering — including infrastructure setup, ETL integration, transformation logic, validation strategy, and debugging in real-world scenarios.

---

## 📚 References & Documentation Consulted

During implementation, the following official documentation and technical resources were referenced:

1. Hevo Blog – Postgres to Snowflake Guide
   [https://hevodata.com/blog/postgres-to-snowflake/](https://hevodata.com/blog/postgres-to-snowflake/)

2. PostgreSQL Documentation – Write-Ahead Logging (WAL) Introduction
   [https://www.postgresql.org/docs/current/wal-intro.html](https://www.postgresql.org/docs/current/wal-intro.html)

3. Hevo Documentation – Configure Snowflake as Destination
   [https://docs.hevodata.com/edge//destinations/snowflake/#create-and-configure-your-snowflake-warehouse](https://docs.hevodata.com/edge//destinations/snowflake/#create-and-configure-your-snowflake-warehouse)

4. Hevo Documentation – Account Regions & Setup
   [https://docs.hevodata.com/getting-started/creating-your-hevo-account/regions/](https://docs.hevodata.com/getting-started/creating-your-hevo-account/regions/)

These resources were used to:

* Understand Postgres replication and WAL behavior
* Configure Snowflake warehouse correctly
* Set up Hevo source-destination pipeline
* Validate region compatibility and networking configuration

All implementation decisions were adapted to the specific environment and project requirements.
