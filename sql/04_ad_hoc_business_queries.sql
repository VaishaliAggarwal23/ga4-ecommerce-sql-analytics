AD-HOC GA4 BUSINESS ANALYSIS QUERIES
  
  Repository: ga4-ecommerce-sql-analytics
  Dataset: bigquery-public-data.ga4_obfuscated_sample_ecommerce
  Description: Collection of deep-dive diagnostic and exploratory SQL queries analyzing marketing efficiency, user drop-offs, and data quality.


Query 1: ROI, AOV, and Conversion Rate Performance
Description: Calculates Return on Investment (ROI), Average Order Value (AOV),and overall purchase conversion rates across traffic sources.

SELECT
  traffic_source.name AS campaign,
  
   1. Total Unique Sessions
  COUNT(DISTINCT CONCAT(user_pseudo_id, (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id'))) AS total_sessions,
  
  2. Unique Purchase Sessions
  COUNT(DISTINCT IF(event_name = 'purchase', CONCAT(user_pseudo_id, (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')), NULL)) AS unique_purchase_sessions,
  
  3. Total Revenue
  ROUND(SUM(IF(event_name = 'purchase', ecommerce.purchase_revenue_in_usd, 0)), 2) AS total_revenue,
  ROUND(
    SAFE_DIVIDE(
      SUM(IF(event_name = 'purchase', ecommerce.purchase_revenue_in_usd, 0)),
      COUNT(DISTINCT IF(event_name = 'purchase', CONCAT(user_pseudo_id, (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')), NULL))
    ), 
    2
  ) AS average_order_value,

  5. Average number of items bought per transaction
  ROUND(
    SAFE_DIVIDE(
      SUM(IF(event_name = 'purchase', ecommerce.total_item_quantity, 0)),
      COUNT(DISTINCT IF(event_name = 'purchase', CONCAT(user_pseudo_id, (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')), NULL))
    ),
    1
  ) AS avg_items_per_order

FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
  AND traffic_source.name NOT IN ('(data deleted)', '<Other>') 
GROUP BY 1
ORDER BY total_revenue DESC;

-----------------------------


Query 2: Page Exit Rate Analysis
Description: Evaluates session exit percentages per page path to pinpoint where traffic drops off most frequently across the site.

  WITH session_pageviews AS (
  SELECT
    CONCAT(user_pseudo_id, COALESCE((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id'), 0)) AS session_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_title') AS page_name,
    ROW_NUMBER() OVER(
      PARTITION BY CONCAT(user_pseudo_id, COALESCE((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id'), 0)) 
      ORDER BY event_timestamp DESC
    ) AS event_rank
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
    AND event_name = 'page_view'
)

SELECT
  page_name,
  COUNT(1) AS total_views,
  COUNT(IF(event_rank = 1, 1, NULL)) AS total_exits,
  ROUND(SAFE_DIVIDE(COUNT(IF(event_rank = 1, 1, NULL)), COUNT(1)) * 100, 2) AS exit_rate
FROM session_pageviews
GROUP BY 1
HAVING total_views > 100
ORDER BY exit_rate DESC
LIMIT 15;

-------------------


Query 3: Broken Pages and Button Click Audit
Description: Identifies 404/broken page routes and unhandled button click events causing user experience friction.

WITH buying_sessions AS (
  SELECT DISTINCT CONCAT(user_pseudo_id, (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')) AS session_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130' 
    AND event_name = 'purchase'
),

user_clicks AS (
  SELECT
    CONCAT(user_pseudo_id, (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')) AS session_id,
    LOWER((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location')) AS page_path,
    COUNT(1) AS click_count
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
  GROUP BY 1, 2
)

SELECT
  c.page_path,
  COUNT(DISTINCT c.session_id) AS stuck_sessions,
  ROUND(AVG(c.click_count), 1) AS avg_rage_clicks
FROM user_clicks c
LEFT JOIN buying_sessions b ON c.session_id = b.session_id
WHERE b.session_id IS NULL 
  AND c.click_count >= 8 
GROUP BY 1
ORDER BY stuck_sessions DESC;


------------------


Query 4: E-commerce Funnel Exploration & Drop-off Diagnostics
Description: Analyzes sequential conversion steps (session_start -> view_item -> add_to_cart -> purchase) to quantify drop-off rates at each stage.


  WITH funnel_stages AS (
  SELECT
    user_pseudo_id,
    
    MAX(IF(event_name = 'view_item', 1, 0)) AS step_1_view,
    
    MAX(IF(event_name = 'add_to_cart', 1, 0)) AS step_2_cart,
    
    MAX(IF(event_name = 'begin_checkout', 1, 0)) AS step_3_checkout,
    
    MAX(IF(event_name = 'purchase', 1, 0)) AS step_4_purchase
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
  GROUP BY
    user_pseudo_id
),

funnel_totals AS (
  SELECT
    SUM(step_1_view) AS users_viewed,
    SUM(IF(step_1_view = 1 AND step_2_cart = 1, 1, 0)) AS users_carted,
    SUM(IF(step_1_view = 1 AND step_2_cart = 1 AND step_3_checkout = 1, 1, 0)) AS users_checked_out,
    SUM(IF(step_1_view = 1 AND step_2_cart = 1 AND step_3_checkout = 1 AND step_4_purchase = 1, 1, 0)) AS users_purchased
  FROM
    funnel_stages
)


---------------
  

Query 5: GA4 Event Parameter & Event Name Debugging
Description: Inspects custom event parameters, unnesting keys and values 
to verify correct tagging setup across custom events.


  SELECT 
  event_name,
  ep.key AS parameter_key,
  COUNT(1) AS occurrence_count
FROM 
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
  UNNEST(event_params) AS ep
WHERE 
  _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
  AND event_name IN ('click', 'page_view') 
GROUP BY 
  1, 2
ORDER BY 
  event_name, occurrence_count DESC;


----------------


Query 6: Bounce Rate & Single-Page Session Analysis
Description: Computes accurate bounce rates by filtering single-page, zero-engagement sessions without additional interaction events.


  WITH session_data AS (
  SELECT
    CONCAT(user_pseudo_id, (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')) AS session_id,
    device.category AS device_category,
    traffic_source.name AS campaign,
    MAX(IF((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'entrances') = 1, 
        LOWER((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location')), NULL)) AS landing_page,
    
    MAX(IF((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'session_engaged') = '1', 1, 0)) AS is_engaged
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
    AND traffic_source.name NOT IN ('(data deleted)', '<Other>')
  GROUP BY 1, 2, 3
)

SELECT
  (Options: landing_page  |  campaign  |  device_category)
 landing_page AS target_dimension,

  COUNT(DISTINCT session_id) AS total_sessions,
  
  ROUND(
    SAFE_DIVIDE(
      COUNT(DISTINCT session_id) - COUNT(DISTINCT IF(is_engaged = 1, session_id, NULL)),
      COUNT(DISTINCT session_id)
    ) * 100, 2
  ) AS bounce_rate
FROM session_data
WHERE landing_page IS NOT NULL
GROUP BY 1 
ORDER BY total_sessions DESC
LIMIT 10;

------------


Query 7: Event-Level Granular Data Validation
Description: Extracts raw event-level rows and timestamps to validate event payload consistency and parameter health.
SELECT 
  event_name,
  LOWER((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location')) AS page_path,
  COUNT(1) AS total_events,
  COUNT(DISTINCT user_pseudo_id) AS total_users
FROM 
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE 
  _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
GROUP BY 
  1, 2
ORDER BY 
  total_events DESC
LIMIT 20;

--------------


Query 8: Timezone Data Reconciliation & Timestamp Standardization
Description: Adjusts UTC raw GA4 timestamps to local target timezones to reconcile daily session counts and reporting windows.

SELECT
  event_date,
  
  EXTRACT(DATE FROM TIMESTAMP_MICROS(event_timestamp) AT TIME ZONE 'America/New_York') AS local_reporting_date,
  
  COUNT(1) AS event_count,
  COUNT(DISTINCT user_pseudo_id) AS user_count
FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
  _TABLE_SUFFIX BETWEEN '20201031' AND '20201102' 
  AND EXTRACT(DATE FROM TIMESTAMP_MICROS(event_timestamp) AT TIME ZONE 'America/New_York') 
      BETWEEN '2020-11-01' AND '2020-11-30'

GROUP BY
  1, 2
ORDER BY
  1, 2;
