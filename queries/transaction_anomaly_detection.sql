-- ============================================================
-- TRANSACTION ANOMALY DETECTION
-- ============================================================

-- Z-score outlier detection on transaction amounts per customer
WITH customer_stats AS (
    SELECT
        customer_id,
        AVG(amount_usd)                                             AS avg_amount,
        STDDEV(amount_usd)                                          AS stddev_amount
    FROM transactions
    WHERE transaction_at >= DATEADD('day', -90, CURRENT_DATE)
    GROUP BY customer_id
    HAVING COUNT(*) >= 5   -- need enough history
),
scored AS (
    SELECT
        t.transaction_id,
        t.customer_id,
        t.amount_usd,
        t.transaction_at,
        s.avg_amount,
        s.stddev_amount,
        ROUND(
            (t.amount_usd - s.avg_amount) / NULLIF(s.stddev_amount, 0), 2
        )                                                           AS z_score
    FROM transactions t
    INNER JOIN customer_stats s USING (customer_id)
)
SELECT
    transaction_id,
    customer_id,
    amount_usd,
    avg_amount,
    z_score,
    CASE
        WHEN ABS(z_score) > 3  THEN 'high_anomaly'
        WHEN ABS(z_score) > 2  THEN 'medium_anomaly'
        ELSE 'normal'
    END                                                             AS anomaly_tier,
    transaction_at
FROM scored
WHERE ABS(z_score) > 2
ORDER BY ABS(z_score) DESC;

-- ============================================================
-- PAYMENT BEHAVIOUR SEGMENTATION
-- ============================================================
-- Cluster customers by repayment consistency for risk tiering
SELECT
    customer_id,
    COUNT(*)                                                        AS total_payments,
    SUM(CASE WHEN payment_status = 'on_time'  THEN 1 ELSE 0 END)   AS on_time_count,
    SUM(CASE WHEN payment_status = 'late'     THEN 1 ELSE 0 END)   AS late_count,
    SUM(CASE WHEN payment_status = 'missed'   THEN 1 ELSE 0 END)   AS missed_count,
    ROUND(
        SUM(CASE WHEN payment_status = 'on_time' THEN 1 ELSE 0 END)
        * 100.0 / NULLIF(COUNT(*), 0), 2)                          AS on_time_rate_pct,
    MAX(days_overdue)                                               AS max_days_overdue,
    AVG(days_overdue)                                               AS avg_days_overdue,
    CASE
        WHEN SUM(CASE WHEN payment_status = 'missed' THEN 1 ELSE 0 END) = 0
         AND AVG(days_overdue) < 2                                  THEN 'prime'
        WHEN SUM(CASE WHEN payment_status = 'missed' THEN 1 ELSE 0 END) <= 1
         AND AVG(days_overdue) < 10                                 THEN 'near_prime'
        WHEN SUM(CASE WHEN payment_status = 'missed' THEN 1 ELSE 0 END) <= 3 THEN 'subprime'
        ELSE 'high_risk'
    END                                                             AS risk_segment
FROM payment_history
GROUP BY customer_id;
