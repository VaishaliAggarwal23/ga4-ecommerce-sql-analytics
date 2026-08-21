# 📊GA4 E-commerce Analytics: Revenue, Funnel & Growth Diagnostics

## 📌 Executive Summary
This project analyzes **Google Analytics 4 (GA4)** e-commerce data hosted in **Google BigQuery** to diagnose revenue bottlenecks, quantify marketing campaign efficiency, and pinpoint critical website user drop-offs. 

The underlying data transformations were engineered using modular **SQL views**, which feed directly into an interactive 5-page **Looker Studio Dashboard** built for business stakeholders and executive decision-makers.

* **🔗 Live Interactive Dashboard:** [View Looker Studio Dashboard](https://datastudio.google.com/reporting/6d0c2820-01da-4a19-ace0-a1e9f5512985)
* **💻 Raw SQL Transformations:** Located in the [`/sql`](./sql) folder.

---
## 🎯 Business Questions

This analysis was designed to answer the following business questions:

1. Which marketing channels and campaigns generate the strongest revenue and purchase performance?
2. Which traffic sources show poor session quality and require further investigation?
3. Where is the largest drop-off in the customer journey?
4. Which products contribute most to e-commerce revenue?
5. Are there technical issues, such as 404/error pages, that may affect the user experience?

---

## 🛠️ Data Architecture & Tech Stack

* **Data Source:** GA4 Public E-commerce Dataset (`bigquery-public-data.ga4_obfuscated_sample_ecommerce`)
* **Data Warehouse:** Google BigQuery
* **Querying & Modeling:** Standard SQL (Nested Record Unnesting, CTEs, Window Functions)
* **Business Intelligence:** Looker Studio

Data Flow: GA4 Raw Event Stream → Google BigQuery Transformations (v_business_performance, v_ux_and_page_analytics, v_funnel_analytics) → Looker Studio Executive Dashboard

---

## 💡 Key Business Findings & Recommendations

1. **High Paid Campaign Bounce Rates:**
   * **Insight:** Non-organic paid channels exhibit elevated bounce rates (~49.8%), signaling poor landing page relevance or mismatched targeting.
   * **Action:** Reallocate ad spend toward top-performing referral channels and high-intent SEO landing pages.

2. **Severe Upper-Funnel Drop-Off:**
   * **Insight:** Over 75% of landing traffic exits between initial entry (`session_start`) and viewing a product (`view_item`).
   * **Action:** Redesign homepage category navigation and hero banners to guide users directly to product pages.

3. **Data Health & Diagnostic Audit:**
   * **Insight:** Identified localized 404 error routes and broken campaign URL parameters impacting user navigation.
   * **Action:** Implement server-side redirects and clean up UTM tracking templates.

---

## 📂 Repository Structure & SQL Files

The [`/sql`](./sql) directory contains all data pipelines and analysis scripts:

* [`sql/01_v_business_performance.sql`](./sql/01_v_business_performance.sql): Aggregates revenue, session volume, purchase counts, and campaign ROI.
* [`sql/02_v_ux_and_page_analytics.sql`](./sql/02_v_ux_and_page_analytics.sql): Models landing page entrances, total pageviews, unique users, and 404 page health.
* [`sql/03_v_funnel_analytics.sql`](./sql/03_v_funnel_analytics.sql): Builds the e-commerce purchase funnel (session_start → view_item → begin_checkout → add_to_cart → purchase) and product performance.
* [`sql/04_ad_hoc_business_queries.sql`](./sql/04_ad_hoc_business_queries.sql): Contains 8 dedicated analytical queries used for deep-dive exploratory data analysis.

---

## 🚀 How to Replicate

1. Connect your Google Cloud Console to the public GA4 dataset.
2. Execute the view queries located in the `/sql` directory in sequential order within BigQuery.
3. Connect Looker Studio to the three newly generated views (`v_business_performance`, `v_ux_and_page_analytics`, `v_funnel_analytics`).
