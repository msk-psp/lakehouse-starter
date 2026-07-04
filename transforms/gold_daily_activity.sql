-- Gold: daily activity metrics, ready for a dashboard / BI tool.
SELECT
    event_date,
    platform,
    count(*)                                            AS events,
    count(DISTINCT user_id)                             AS active_users,
    sum(CASE WHEN event = 'purchase' THEN 1 ELSE 0 END) AS purchases
FROM silver.events
GROUP BY event_date, platform
ORDER BY event_date, platform
