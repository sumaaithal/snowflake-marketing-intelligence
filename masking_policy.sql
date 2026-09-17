USE ROLE snowflake_intelligence_admin;
USE SCHEMA dash_db_si.retail;

-- 1. Create the policy
CREATE OR REPLACE MASKING POLICY mask_engagement_clicks AS (val number) 
RETURNS number ->
  CASE 
    WHEN CURRENT_ROLE() IN ('SNOWFLAKE_INTELLIGENCE_ADMIN', 'ACCOUNTADMIN') THEN val 
    ELSE 0 -- Masked value for other roles
  END;

-- 2. Apply the policy to the base table column
ALTER TABLE marketing_campaign_metrics MODIFY COLUMN clicks SET MASKING POLICY mask_engagement_clicks;

-- 3. Verify the policy is active
SELECT * FROM TABLE(INFORMATION_SCHEMA.POLICY_REFERENCES(
    policy_name => 'mask_engagement_clicks'
));
