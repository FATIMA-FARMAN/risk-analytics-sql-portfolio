-- ============================================================
-- FRAUD PATTERN DETECTION
-- ============================================================

-- Velocity check: flag customers with abnormal transaction bursts
SELECT
    customer_id,
    DATE_TRUNC('hour', transaction_at)              AS hour_bucket,
    COUNT(*)                                         AS txn_count,
    SUM(amount_usd)                                  AS total_amount_usd,
    CASE
        WHEN COUNT(*) > 10 THEN 'high_velocity'
        WHEN COUNT(*) > 5  THEN 'medium_velocity'
        ELSE 'normal'
    END                                              AS velocity_flag
FROM transactions
GROUP BY 1, 2
HAVING COUNT(*) > 3
ORDER BY txn_count DESC;

-- ============================================================
-- MERCHANT FRAUD CONCENTRATION
-- ============================================================
-- Merchants with above-average fraud rates
WITH merchant_stats AS (
    SELECT
        merchant_id,
        COUNT(*)                                                    AS total_txns,
        COUNT(CASE WHEN is_fraud = true THEN 1 END)                 AS fraud_txns,
        ROUND(COUNT(CASE WHEN is_fraud = true THEN 1 END)
              * 100.0 / NULLIF(COUNT(*), 0), 2)                    AS fraud_rate_pct,
        SUM(CASE WHEN is_fraud = true THEN amount_usd END)          AS fraud_exposure_usd
    FROM transactions
    GROUP BY merchant_id
),
avg_fraud_rate AS (
    SELECT AVG(fraud_rate_pct) AS platform_avg_fraud_pct
    FROM merchant_stats
)
SELECT
    m.merchant_id,
    m.total_txns,
    m.fraud_txns,
    m.fraud_rate_pct,
    m.fraud_exposure_usd,
    ROUND(m.fraud_rate_pct - a.platform_avg_fraud_pct, 2)          AS vs_platform_avg_pct,
    CASE
        WHEN m.fraud_rate_pct > a.platform_avg_fraud_pct * 2 THEN 'critical'
        WHEN m.fraud_rate_pct > a.platform_avg_fraud_pct     THEN 'elevated'
        ELSE 'normal'
    END                                                             AS risk_level
FROM merchant_stats m
CROSS JOIN avg_fraud_rate a
ORDER BY m.fraud_rate_pct DESC;

-- ============================================================
-- DEVICE + LOCATION ANOMALY SIGNALS
-- ============================================================
-- Customers transacting from unusually high number of devices/IPs
SELECT
    customer_id,
    COUNT(DISTINCT device_fingerprint)                              AS unique_devices,
    COUNT(DISTINCT ip_address)                                      AS unique_ips,
    COUNT(DISTINCT country_code)                                    AS unique_countries,
    MIN(transaction_at)                                             AS first_seen,
    MAX(transaction_at)                                             AS last_seen,
    CASE
        WHEN COUNT(DISTINCT device_fingerprint) > 5
          OR COUNT(DISTINCT country_code) > 2 THEN 'suspicious'
        ELSE 'normal'
    END                                                             AS anomaly_flag
FROM transactions
WHERE transaction_at >= DATEADD('day', -30, CURRENT_DATE)
GROUP BY customer_id
HAVING COUNT(DISTINCT device_fingerprint) > 3
    OR COUNT(DISTINCT country_code) > 1
ORDER BY unique_devices DESC;
