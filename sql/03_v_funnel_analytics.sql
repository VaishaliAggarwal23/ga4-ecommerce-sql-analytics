Model: v_funnel_analytics
Description: Tracks user drop-off across the correct e-commerce conversion funnel 
(session_start -> view_item -> add_to_cart -> begin_checkout -> purchase)
Target Dashboard: Looker Studio Funnel & Drop-off Page


SELECT
  PARSE_DATE('%Y%m%d', event_date) AS date,
  event_name AS funnel_step,
  
  CASE 
    WHEN event_name = 'session_start' THEN 1
    WHEN event_name = 'view_item' THEN 2
    WHEN event_name = 'add_to_cart' THEN 3
    WHEN event_name = 'begin_checkout' THEN 4
    WHEN event_name = 'purchase' THEN 5
  END AS funnel_step_order,

  CAST(NULL AS STRING) AS item_name,
  'Funnel Step' AS metric_type,

 
  COUNT(1) AS step_count,
  COUNT(DISTINCT CONCAT(user_pseudo_id, (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id'))) AS unique_sessions,

  
  0 AS items_added_to_cart,
  0 AS items_purchased,
  0.0 AS item_revenue

FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
  AND event_name IN ('session_start', 'view_item', 'add_to_cart', 'begin_checkout', 'purchase')
GROUP BY 1, 2, 3, 4, 5

UNION ALL


SELECT
  PARSE_DATE('%Y%m%d', e.event_date) AS date,
  'Item Analysis' AS funnel_step,
  99 AS funnel_step_order,
  i.item_name AS item_name,
  'Item Performance' AS metric_type,

  0 AS step_count,
  0 AS unique_sessions,

 
  SUM(IF(e.event_name = 'add_to_cart', i.quantity, 0)) AS items_added_to_cart,
  SUM(IF(e.event_name = 'purchase', i.quantity, 0)) AS items_purchased,
  ROUND(SUM(IF(e.event_name = 'purchase', i.item_revenue_in_usd, 0)), 2) AS item_revenue

FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` e,
UNNEST(e.items) i
WHERE e._TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
  AND i.item_name IS NOT NULL
  AND i.item_name != '(not set)'
GROUP BY 1, 2, 3, 4, 5
