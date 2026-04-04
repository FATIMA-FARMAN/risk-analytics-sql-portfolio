-- ============================================================
-- CREDIT RISK SCORING
-- ============================================================

-- Risk tier by customer repayment behaviour
SELECT
    customer_id,
    COUNT(*)                                                                AS total_installments,
    COUNT(CASE WHEN payment_status = 'missed'  THEN 1 END)                 AS missed_payments,
    COUNT(CASE WHEN payment_status = 'late'    THEN 1 END)                 AS late_payments,
    ROUND(COUNT(CASE WHEN payment_status = 'missed' THEN 1 END)
          * 100.0 / COUNT(*), 2)                                            AS miss_rate_pct,
    CASE
        WHEN COUNT(CASE WHEN payment_status = 'missed' THEN 1 END) = 0     THEN 'Low'
        WHEN COUNT(CASE WHEN payment_status = 'missed' THEN 1 END) <= 2    THEN 'Medium'
        ELSE 'High'
    END                                                                     AS risk_tier
FROM installments
GROUP BY customer_id;

-- ============================================================
-- DELINQUENCY BUCKET ANALYSIS (30 / 60 / 90 day)
-- ============================================================
SELECT
    CASE
        WHEN days_overdue BETWEEN 1  AND 30 THEN '1-30 days'
        WHEN days_overdue BETWEEN 31 AND 60 THEN '31-60 days'
        WHEN days_overdue BETWEEN 61 AND 90 THEN '61-90 days'
        ELSE '90+ days'
    END                                AS bucket,
    COUNT(*)                           AS accounts,
    SUM(outstanding_balance)           AS total_exposure,
    ROUND(AVG(outstanding_balance), 2) AS avg_exposure
FROM overdue_accounts
WHERE days_overdue > 0
GROUP BY 1
ORDER BY MIN(days_overdue);

-- ============================================================
-- DEFAULT PREDICTION FEATURES
-- ============================================================
SELECT
    c.customer_id,
    c.credit_limit,
    c.customer_segment,
    COUNT(i.installment_id)                                                 AS total_installments,
    SUM(CASE WHEN i.payment_status = 'missed' THEN 1 ELSE 0 END)           AS missed_count,
    MAX(i.days_overdue)                                                     AS max_days_overdue,
    AVG(i.days_overdue)                                                     AS avg_days_overdue,
    SUM(i.installment_amount)                                               AS total_owed,
    SUM(CASE WHEN i.payment_status = 'paid'
             THEN i.installment_amount ELSE 0 END)                         AS total_paid,
    ROUND(SUM(CASE WHEN i.payment_status = 'paid'
                   THEN i.installment_amount ELSE 0 END)
          / NULLIF(SUM(i.installment_amount), 0) * 100, 2)                 AS repayment_rate_pct
FROM customers c
LEFT JOIN installments i USING (customer_id)
GROUP BY c.customer_id, c.credit_limit, c.customer_segment;

-- ============================================================
-- PORTFOLIO HEALTH SUMMARY
-- ============================================================
SELECT
    DATE_TRUNC('month', due_date)      AS month,
    COUNT(*)                           AS total_installments,
    SUM(installment_amount)            AS total_due,
    SUM(CASE WHEN payment_status = 'paid'   THEN installment_amount END)   AS collected,
    SUM(CASE WHEN payment_status = 'missed' THEN installment_amount END)   AS at_risk,
    ROUND(SUM(CASE WHEN payment_status = 'missed' THEN installment_amount END)
          / NULLIF(SUM(installment_amount), 0) * 100, 2)                   AS at_risk_pct
FROM installments
GROUP BY 1
ORDER BY 1;
