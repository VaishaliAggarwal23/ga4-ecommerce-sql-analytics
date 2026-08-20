Model: v_business_performance
Description: Aggregates revenue, session totals, transaction counts, and bounce rates by traffic source/medium and campaign.
Target Dashboard: Looker Studio Page 1 & Page 2
  
SELECT
  PARSE_DATE('%Y%m%d', event_date) AS date,
  COALESCE(traffic_source.name, '(direct)') AS campaign,
  'ROI & Revenue' AS metric_type,

  COUNT(DISTINCT CONCAT(user_pseudo_id, (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id'))) AS total_sessions,
  COUNT(DISTINCT IF(event_name = 'purchase', CONCAT(user_pseudo_id, (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')), NULL)) AS unique_purchase_sessions,
  ROUND(SUM(IF(event_name = 'purchase', ecommerce.purchase_revenue_in_usd, 0)), 2) AS total_revenue,
  ROUND(
    SAFE_DIVIDE(
      SUM(IF(event_name = 'purchase', ecommerce.purchase_revenue_in_usd, 0)),
      COUNT(DISTINCT IF(event_name = 'purchase', CONCAT(user_pseudo_id, (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')), NULL))
    ), 2
  ) AS average_order_value,
  ROUND(
    SAFE_DIVIDE(
      SUM(IF(event_name = 'purchase', ecommerce.total_item_quantity, 0)),
      COUNT(DISTINCT IF(event_name = 'purchase', CONCAT(user_pseudo_id, (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')), NULL))
    ), 1
  ) AS avg_items_per_order,

  CAST(NULL AS FLOAT64) AS bounce_rate,
  0 AS total_events,
  0 AS total_users

FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
GROUP BY 1, 2, 3

UNION ALL

-- ========================================================
-- PART 2: ULTIMATE BOUNCE RATE
-- ========================================================
SELECT
  PARSE_DATE('%Y%m%d', event_date) AS date,
  COALESCE(traffic_source.name, '(direct)') AS campaign,
  'Bounce Rate' AS metric_type,

  COUNT(DISTINCT CONCAT(user_pseudo_id, (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id'))) AS total_sessions,
  0 AS unique_purchase_sessions,
  0.0 AS total_revenue,
  0.0 AS average_order_value,
  0.0 AS avg_items_per_order,

  ROUND(
    SAFE_DIVIDE(
      COUNT(DISTINCT CONCAT(user_pseudo_id, (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id'))) - 
      COUNT(DISTINCT IF((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'session_engaged') = '1', CONCAT(user_pseudo_id, (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')), NULL)),
      COUNT(DISTINCT CONCAT(user_pseudo_id, (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')))
    ) * 100, 2
  ) AS bounce_rate,

  0 AS total_events,
  0 AS total_users

FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
GROUP BY 1, 2, 3

UNION ALL

-- ========================================================
-- PART 3: DATA RECONCILIATION & TIMEZONE
-- ========================================================
SELECT
  EXTRACT(DATE FROM TIMESTAMP_MICROS(event_timestamp) AT TIME ZONE 'America/New_York') AS date,
  COALESCE(traffic_source.name, '(direct)') AS campaign,
  'Data Reconciliation' AS metric_type,

  0 AS total_sessions,
  0 AS unique_purchase_sessions,
  0.0 AS total_revenue,
  0.0 AS average_order_value,
  0.0 AS avg_items_per_order,
  CAST(NULL AS FLOAT64) AS bounce_rate,

  COUNT(1) AS total_events,
  COUNT(DISTINCT user_pseudo_id) AS total_users

FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
GROUP BY 1, 2, 3
