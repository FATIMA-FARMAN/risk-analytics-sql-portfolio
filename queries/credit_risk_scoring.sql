-- Credit Risk Scoring
SELECT
    customer_id,
    COUNT(CASE WHEN payment_status = 'missed' THEN 1 END)          AS missed_payments,
    COUNT(*)                                                          AS total_installments,
    ROUND(COUNT(CASE WHEN payment_status = 'missed' THEN 1 END)
          * 100.0 / COUNT(*), 1)                                     AS miss_rate,
    CASE
        WHEN COUNT(CASE WHEN payment_status = 'missed' THEN 1 END) = 0 THEN 'Low'
        WHEN COUNT(CASE WHEN payment_status = 'missed' THEN 1 END) <= 2 THEN 'Medium'
        ELSE 'High'
    END                                                               AS risk_tier
FROM installments
GROUP BY customer_id;

-- Delinquency Buckets (30/60/90 day)
SELECT
    CASE
        WHEN days_overdue BETWEEN 1  AND 30 THEN '1-30 days'
        WHEN days_overdue BETWEEN 31 AND 60 THEN '31-60 days'
        WHEN days_overdue BETWEEN 61 AND 90 THEN '61-90 days'
        ELSE '90+ days'
    END                           AS bucket,
    COUNT(*)                      AS accounts,
    SUM(outstanding_balance)      AS total_exposure
FROM overdue_accounts
WHERE days_overdue > 0
GROUP BY 1
ORDER BY MIN(days_overdue);
