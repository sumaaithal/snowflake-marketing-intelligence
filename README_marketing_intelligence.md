# Snowflake Intelligence: Marketing Analytics & AI Enrichment

A Snowflake-based marketing intelligence project that combines campaign performance, product, sales, social-media, and customer-support data with **Snowflake Cortex AI**, **Dynamic Tables**, **secure views**, **RBAC**, and **column-level masking**.

The project demonstrates how marketing data can be prepared for natural-language analytics while applying role-based controls to sensitive engagement metrics.

## Overview

The workflow covers four main areas:

1. **Marketing analytics data setup** — creates the Snowflake environment and loads marketing, product, sales, social-media, and support datasets.
2. **AI enrichment** — uses Snowflake Cortex sentiment analysis and issue classification on customer-support transcripts and creates an enriched Dynamic Table.
3. **Semantic access layer** — exposes marketing metrics through a secure view.
4. **Data governance** — applies a masking policy to campaign click data and verifies different access levels through dedicated roles.

```text
Marketing Data
     │
     ├── Marketing Campaign Metrics
     ├── Products
     ├── Sales
     ├── Social Media
     └── Support Cases
              │
              ▼
       Cortex AI Enrichment
              │
       ┌──────┴──────┐
       │             │
   Sentiment     Issue Category
       │             │
       └──────┬──────┘
              ▼
  enriched_marketing_intelligence
        (Dynamic Table)
              │
              ▼
   marketing_intelligence_view
              │
              ▼
     Role-Based Access
       │             │
       ▼             ▼
 Marketing Role    Admin Role
  Masked clicks    Actual clicks
```

## Snowflake Objects

The setup creates or uses the following environment:

| Object | Name |
|---|---|
| Database | `DASH_DB_SI` |
| Schema | `DASH_DB_SI.RETAIL` |
| Warehouse | `DASH_WH_SI` |
| Admin Role | `SNOWFLAKE_INTELLIGENCE_ADMIN` |
| Marketing Role | `MARKETING_INTELLIGENCE_ROLE` |
| AI Database | `SNOWFLAKE_INTELLIGENCE` |
| AI Schema | `SNOWFLAKE_INTELLIGENCE.AGENTS` |

The setup script also creates stages, a file format, a Git integration/repository, an email notification integration, and a Python stored procedure for sending email.

## Data Model

### Marketing Campaign Metrics

The primary marketing dataset contains:

- `DATE`
- `CATEGORY`
- `CAMPAIGN_NAME`
- `IMPRESSIONS`
- `CLICKS`

The included `marketing_data.csv` contains campaign performance observations across product categories and campaign periods from January through October 2025.

### Supporting Datasets

The Snowflake setup also creates:

**Products**

```text
PRODUCT_ID
PRODUCT_NAME
CATEGORY
```

**Sales**

```text
DATE
REGION
PRODUCT_ID
UNITS_SOLD
SALES_AMOUNT
```

**Social Media**

```text
DATE
CATEGORY
PLATFORM
INFLUENCER
MENTIONS
```

**Support Cases**

```text
ID
TITLE
PRODUCT
TRANSCRIPT
DATE
```

## Cortex AI Enrichment

The project uses Snowflake Cortex functions against customer-support transcripts.

### Sentiment Analysis

`extract_trends.sql` calculates a sentiment score for each support case:

```sql
SNOWFLAKE.CORTEX.AI_SENTIMENT(transcript)
```

### Issue Classification

Support transcripts are classified into:

```text
Return
Quality
Shipping
```

using:

```sql
SNOWFLAKE.CORTEX.AI_CLASSIFY(
    transcript,
    ['Return', 'Quality', 'Shipping']
)
```

Before extraction, the script also standardizes a product value:

```sql
UPDATE support_cases
SET product = 'Fitness Wear'
WHERE product = 'ThermoJacket Pro';
```

## AI-Enriched Dynamic Table

`ai_enrichment.sql` creates the Dynamic Table:

```text
DASH_DB_SI.RETAIL.ENRICHED_MARKETING_INTELLIGENCE
```

Configuration:

```text
TARGET_LAG = '1 hours'
WAREHOUSE  = DASH_WH_SI
```

The Dynamic Table joins campaign metrics with support-case data using:

```sql
m.category = s.product
```

and derives a sentiment value from the support transcript.

Conceptually:

```text
Marketing Campaign
       │
       │ category
       ▼
Support Case
       │
       │ transcript
       ▼
Cortex Sentiment
       │
       ▼
Enriched Marketing Intelligence
```

## Secure Semantic View

`role_grant.sql` creates the secure view:

```text
DASH_DB_SI.RETAIL.MARKETING_INTELLIGENCE_VIEW
```

The view exposes business-friendly column names:

| Source column | View column |
|---|---|
| `CAMPAIGN_NAME` | `Ad Campaign` |
| `CATEGORY` | `Product Category` |
| `CLICKS` | `Engagement Clicks` |
| Constant `0` | `Customer Sentiment Score` |

The current SQL explicitly sets `Customer Sentiment Score` to `0` in this view; the comment indicates that sentiment is intended to come from the Dynamic Table, but the supplied view definition does not currently select that Dynamic Table.

## Data Governance & Masking

The project demonstrates column-level security through a Snowflake masking policy.

### Masking Policy

`masking_policy.sql` creates:

```text
MASK_ENGAGEMENT_CLICKS
```

The policy is applied to:

```text
MARKETING_CAMPAIGN_METRICS.CLICKS
```

The behavior is:

```text
SNOWFLAKE_INTELLIGENCE_ADMIN → actual clicks
ACCOUNTADMIN                  → actual clicks
Other roles                   → 0
```

This allows the same analytical object to be exposed to different users while protecting the underlying engagement metric from unauthorized roles.

## Role-Based Access Control

`role_grant.sql` creates:

```text
MARKETING_INTELLIGENCE_ROLE
```

and grants it:

- Usage on `DASH_WH_SI`
- Usage on `DASH_DB_SI`
- Usage on `DASH_DB_SI.RETAIL`
- `SNOWFLAKE.CORTEX_USER`
- `SELECT` on `MARKETING_INTELLIGENCE_VIEW`

The role is then assigned to the current user for testing.

### Access Verification

The repository includes two verification scripts.

#### Marketing Role

`verify_as_marketing.sql`

Runs as:

```sql
USE ROLE MARKETING_INTELLIGENCE_ROLE;
```

and queries the semantic view.

Because `CLICKS` is protected by the masking policy, the expected result for the engagement-click field is `0` for this role.

#### Admin Role

`verify_as_admin.sql`

Runs as:

```sql
USE ROLE SNOWFLAKE_INTELLIGENCE_ADMIN;
```

and queries the same view.

The expected result is the underlying click values rather than the masked value.

This demonstrates that access control is enforced at the data layer rather than by creating separate copies of the dataset.

## Setup

### Prerequisites

You need a Snowflake account with permissions to create:

- Roles
- Databases
- Schemas
- Warehouses
- Stages
- Tables
- Dynamic Tables
- Secure views
- Masking policies
- Integrations

Cortex AI capabilities must also be available for the account/region being used.

### 1. Create the Snowflake Environment

Run the setup script:

```sql
setup(1).sql
```

or the equivalent:

```text
setup-2.sql
```

The supplied scripts contain the same overall environment/bootstrap workflow. Use one setup script rather than executing both against the same environment.

The setup creates the required database, schema, warehouse, source tables, stages, Git integration, semantic-model stage, notification integration, and email procedure.

### 2. Load Marketing Data

The repository includes:

```text
marketing_data.csv
```

The setup SQL also contains a staged loading workflow for the marketing dataset.

The marketing table schema is:

```sql
CREATE TABLE marketing_campaign_metrics (
    date DATE,
    category VARCHAR,
    campaign_name VARCHAR,
    impressions NUMBER,
    clicks NUMBER
);
```

### 3. Create the AI-Enriched Dynamic Table

Run:

```text
ai_enrichment.sql
```

This creates:

```text
DASH_DB_SI.RETAIL.ENRICHED_MARKETING_INTELLIGENCE
```

### 4. Create the Secure View and Role

Run:

```text
role_grant.sql
```

This creates the secure view and the `MARKETING_INTELLIGENCE_ROLE`, then grants the required privileges.

### 5. Apply the Masking Policy

Run:

```text
masking_policy.sql
```

This applies the click-masking policy to the base marketing table.

### 6. Verify Access

As the marketing role:

```text
verify_as_marketing.sql
```

As the administrator role:

```text
verify_as_admin.sql
```

The two queries are intended to demonstrate different visibility of the same `CLICKS` data.

### 7. Run Cortex Trend Extraction

Run:

```text
extract_trends.sql
```

This performs sentiment analysis and issue classification on support transcripts.

## Repository Structure

```text
.
├── marketing_data.csv
├── setup(1).sql
├── setup-2.sql
├── extract_trends.sql
├── ai_enrichment.sql
├── role_grant.sql
├── masking_policy.sql
├── verify_as_marketing.sql
└── verify_as_admin.sql
```

## File Guide

| File | Purpose |
|---|---|
| `marketing_data.csv` | Marketing campaign metrics dataset |
| `setup(1).sql` | Full Snowflake environment/bootstrap setup |
| `setup-2.sql` | Setup/bootstrap script containing the same core environment definition |
| `extract_trends.sql` | Cortex sentiment analysis and support-issue classification |
| `ai_enrichment.sql` | Creates the AI-enriched Dynamic Table |
| `role_grant.sql` | Creates secure view, role, and grants |
| `masking_policy.sql` | Creates and applies click masking |
| `verify_as_marketing.sql` | Tests access as marketing role |
| `verify_as_admin.sql` | Tests access as administrator |

## Key Snowflake Concepts Demonstrated

### Snowflake Cortex

Uses AI functions directly from SQL for:

- Sentiment analysis
- Text classification

### Dynamic Tables

Uses a Dynamic Table to maintain an enriched analytical dataset with a one-hour target lag.

### Secure Views

Provides a controlled business-facing interface over marketing data.

### Masking Policies

Protects engagement-click data based on the current Snowflake role.

### RBAC

Separates administrative access from marketing-user access while granting the minimum privileges required by the marketing role.

### External Stages

Loads source datasets through Snowflake stages backed by S3 locations used by the supplied setup.

### Git Integration

The setup creates a Snowflake Git API integration and Git repository and copies the `marketing_campaigns.yaml` semantic model into the `semantic_models` stage.

### Notifications

The setup creates an email notification integration and a Python stored procedure using Snowpark to invoke `SYSTEM$SEND_EMAIL`.

## Security Model

The core security pattern is:

```text
                    marketing_campaign_metrics
                              │
                              │
                       masking policy
                              │
                ┌─────────────┴─────────────┐
                │                           │
                ▼                           ▼
   SNOWFLAKE_INTELLIGENCE_ADMIN   MARKETING_INTELLIGENCE_ROLE
                │                           │
                ▼                           ▼
        Actual click values              0
```

This demonstrates **policy-based data protection** rather than application-level filtering.

## Implementation Notes

The supplied SQL contains a few intentionally visible implementation details that should be reviewed before production use:

- `extract_trends.sql` uses `AI_SENTIMENT` and `AI_CLASSIFY`, while `ai_enrichment.sql` uses `SNOWFLAKE.CORTEX.SENTIMENT`. The repository preserves the functions exactly as supplied.
- The secure view currently returns `0` as `"Customer Sentiment Score"` rather than selecting the sentiment generated by `ENRICHED_MARKETING_INTELLIGENCE`.
- `ai_enrichment.sql` joins marketing categories to support-case products directly. The resulting grain and potential row multiplication should be reviewed if this moves beyond the supplied demonstration dataset.
- `setup(1).sql` and `setup-2.sql` both contain bootstrap logic. They should not both be run unnecessarily against the same environment.
- The setup changes the account-level Cortex cross-region setting to `AWS_US`; this should be reviewed against the target account's governance and regional requirements before use outside a workshop environment.
- The setup and role scripts use powerful administrative privileges. A production implementation should apply an appropriately scoped deployment/security model.

These notes describe the current supplied implementation; they are not changes to the SQL.

## Example Use Cases

The resulting environment can support analytical questions such as:

```text
Which campaigns generated the most engagement?

How are impressions and clicks distributed by product category?

What sentiment themes appear in customer support transcripts?

What types of issues are customers reporting?

How does campaign performance relate to customer-support signals?

Which users should be able to see raw engagement metrics?
```

The current repository provides the underlying SQL components for these workflows; it does not include a completed natural-language agent definition beyond the semantic-model staging setup.

## Portfolio Takeaway

This project demonstrates a practical progression from **raw marketing data → AI enrichment → governed semantic access → role-aware analytics**.

It combines data engineering, analytics engineering, AI/ML functions, and Snowflake governance in a single workflow:

```text
Data Loading
     ↓
Data Transformation
     ↓
Cortex AI Enrichment
     ↓
Dynamic Table
     ↓
Secure View
     ↓
RBAC + Masking
     ↓
Controlled Analytics
```

## Author

**Suma Aithal**

Data Engineering / Analytics Engineering portfolio project focused on Snowflake, Cortex AI, Dynamic Tables, semantic access, and data governance.
