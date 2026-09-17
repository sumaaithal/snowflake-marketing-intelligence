USE DATABASE DASH_DB_SI;
USE SCHEMA RETAIL;
UPDATE support_cases SET product = 'Fitness Wear' WHERE product = 'ThermoJacket Pro';
SELECT 
    title,
    SNOWFLAKE.CORTEX.AI_SENTIMENT(transcript) AS sentiment_score,
    SNOWFLAKE.CORTEX.AI_CLASSIFY(transcript, ['Return', 'Quality', 'Shipping']) AS issue_category
FROM support_cases;
