USE DATABASE DASH_DB_SI;
USE SCHEMA RETAIL;

-- Create the Semantic View
CREATE OR REPLACE SECURE VIEW marketing_intelligence_view AS
SELECT 
    campaign_name AS "Ad Campaign",
    category AS "Product Category",
    clicks AS "Engagement Clicks",
    -- avg_sentiment will come from the Dynamic Table
    0 AS "Customer Sentiment Score" 
FROM marketing_campaign_metrics;

-- Check which roles have access to your database and schema
SHOW GRANTS ON DATABASE dash_db_si;
SHOW GRANTS ON SCHEMA dash_db_si.retail;

-- Check specifically for your Semantic View
SHOW GRANTS ON VIEW marketing_intelligence_view;

USE ROLE snowflake_intelligence_admin;
USE WAREHOUSE dash_wh_si;

-- You should see the actual budget/click numbers
SELECT * FROM marketing_intelligence_view LIMIT 5;

USE ROLE ACCOUNTADMIN;

-- Create the role
CREATE OR REPLACE ROLE marketing_intelligence_role;

-- Grant usage on the warehouse and database
GRANT USAGE ON WAREHOUSE dash_wh_si TO ROLE marketing_intelligence_role;
GRANT USAGE ON DATABASE dash_db_si TO ROLE marketing_intelligence_role;
GRANT USAGE ON SCHEMA dash_db_si.retail TO ROLE marketing_intelligence_role;

-- Grant access to the AI functions and the specific views
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE marketing_intelligence_role;
GRANT SELECT ON VIEW dash_db_si.retail.marketing_intelligence_view TO ROLE marketing_intelligence_role;

-- Assign to yourself for testing
SET current_user = CURRENT_USER();
GRANT ROLE marketing_intelligence_role TO USER IDENTIFIER($CURRENT_USER);
