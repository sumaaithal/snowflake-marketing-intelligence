-- Re-run the view to ensure it picks up the table-level masking
CREATE OR REPLACE SECURE VIEW dash_db_si.retail.marketing_intelligence_view AS
SELECT 
    campaign_name AS "Ad Campaign",
    category AS "Product Category",
    clicks AS "Engagement Clicks",
    -- avg_sentiment will come from the Dynamic Table
    0 AS "Customer Sentiment Score" 
FROM marketing_campaign_metrics;

USE ROLE snowflake_intelligence_admin;
USE SCHEMA dash_db_si.retail;
-- You should see numbers like 11103
SELECT "Ad Campaign", "Engagement Clicks" FROM marketing_intelligence_view;
