# Risk Analytics SQL Portfolio

**SQL-based risk analytics** across three domains: fraud detection, credit scoring, and transaction anomaly detection — built for FinTech and BNPL environments.

---

## Queries

| File | What it answers |
|------|----------------|
| [`credit_risk_scoring.sql`](queries/credit_risk_scoring.sql) | Risk tier by repayment behaviour · Delinquency buckets · Portfolio health |
| [`fraud_pattern_detection.sql`](queries/fraud_pattern_detection.sql) | Velocity flags · Merchant fraud concentration · Device/location anomalies |
| [`transaction_anomaly_detection.sql`](queries/transaction_anomaly_detection.sql) | Z-score outlier detection · Payment behaviour segmentation |

---

## Sample Output: Credit Risk Scoring

```
customer_id | total_installments | missed_payments | miss_rate_pct | risk_tier
------------|-------------------|-----------------|---------------|----------
C001        | 12                | 0               | 0.00          | Low
C002        | 10                | 1               | 10.00         | Medium
C003        |  8                | 4               | 50.00         | High
```

## Sample Output: Delinquency Buckets

```
bucket      | accounts | total_exposure | avg_exposure
------------|----------|----------------|-------------
1-30 days   |      412 |    $1,823,400  |    $4,425
31-60 days  |      187 |      $946,200  |    $5,060
61-90 days  |       93 |      $571,800  |    $6,148
90+ days    |       41 |      $394,400  |    $9,619
```

## Sample Output: Fraud Concentration by Merchant

```
merchant_id | fraud_rate_pct | vs_platform_avg_pct | risk_level
------------|---------------|---------------------|------------
M047        |          4.82 |               +3.21 | critical
M019        |          2.61 |               +1.00 | elevated
M003        |          1.11 |               -0.50 | normal
```

---

## Metrics Covered

**Credit Risk**
- Risk tier classification (Low / Medium / High) by missed payment rate
- Delinquency bucket analysis (1-30 / 31-60 / 61-90 / 90+ days)
- Portfolio health: collected vs at-risk by month
- Default prediction feature set (repayment rate, max days overdue)

**Fraud Detection**
- Transaction velocity flags by customer and hour
- Merchant fraud concentration vs platform average
- Device fingerprint and country anomaly signals

**Anomaly Detection**
- Z-score outlier detection on transaction amounts per customer
- Payment behaviour segmentation: prime / near-prime / subprime / high-risk

---

## Stack

- **SQL** — BigQuery dialect (compatible with Snowflake / DuckDB with minor adjustments)
- Designed to feed into dbt models or BI dashboards directly

---

Fatima Farman · fatimafarman.fc@gmail.com · [LinkedIn](https://www.linkedin.com/in/fatima-farman)

