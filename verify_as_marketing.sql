USE ROLE marketing_intelligence_role;
USE SCHEMA dash_db_si.retail;
-- You should see 0 for all clicks
SELECT "Ad Campaign", "Engagement Clicks" FROM marketing_intelligence_view;
