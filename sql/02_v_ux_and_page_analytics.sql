Model: v_ux_and_page_analytics
Description: Unnests page paths to track landing entrances, page views,unique users, and identifies 404/error page routes.
Target Dashboard: Looker Studio Page 2 & Page 3

SELECT
  PARSE_DATE('%Y%m%d', event_date) AS date,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS page_path,
  'Landing Page' AS metric_type,

  -- Landing Page Metrics
  COUNT(DISTINCT IF(event_name = 'first_visit', CONCAT(user_pseudo_id, (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')), NULL)) AS entrances,
  COUNT(DISTINCT CONCAT(user_pseudo_id, (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id'))) AS total_sessions,
  
  -- Null Placeholders for General Page Views
  0 AS page_views,
  0 AS total_users

FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
GROUP BY 1, 2, 3

UNION ALL

-- ========================================================
-- PART 2: PAGE PATH & USER ENGAGEMENT
-- ========================================================
SELECT
  PARSE_DATE('%Y%m%d', event_date) AS date,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS page_path,
  'Page Performance' AS metric_type,

  0 AS entrances,
  0 AS total_sessions,

  --Page View & User Metrics
  COUNT(IF(event_name = 'page_view', 1, NULL)) AS page_views,
  COUNT(DISTINCT user_pseudo_id) AS total_users

FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
GROUP BY 1, 2, 3
