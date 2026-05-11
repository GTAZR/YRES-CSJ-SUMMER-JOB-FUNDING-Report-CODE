# YRES-CSJ-SUMMER-JOB-FUNDING-Report-CODE

[README.md](https://github.com/user-attachments/files/27606997/README.md)
# Canada Summer Jobs (CSJ) Funding Analysis
### End-to-End Data Analytics Pipeline | 2017–2025 | AB · BC · ON

> **Objective:** Analyse 9 years of federal CSJ funding data across 3 Canadian provinces to help YRES understand summer job market trends, forecast 2026 funding, and identify major competitors for strategic expansion planning.

---

## Project Overview

Canada Summer Jobs (CSJ) is a federal government programme that funds organisations across Canada to create summer employment for youth. This project builds a complete analytics pipeline — from raw government data to strategic business insights — covering **137,521 records** across **198 electoral constituencies** in Alberta, British Columbia, and Ontario.

---

## Tech Stack

| Layer | Tools |
|-------|-------|
| Database | DuckDB |
| SQL Analysis | DBeaver |
| Data Processing | Python · Pandas |
| Machine Learning | scikit-learn (Linear Regression) |
| Visualisation | Tableau |
| Reporting | Python · openpyxl |

---

## Pipeline Architecture

```
Raw CSV (Government Open Data)
        ↓
┌─────────────────────────────┐
│   LAYER 1: RAW              │  raw_csj — original data, never modified
│   LAYER 2: STAGING          │  stg_csj — cleaned, standardised
│   LAYER 3: MART             │  6 analytical tables for delivery
└─────────────────────────────┘
        ↓
Python Automation
        ↓
Tableau Dashboards + Excel Report + ML Forecast
```

---

## Repository Structure

```
csj-analysis/
│
├── data/
│   └── csj-dataset-AB-BC-ON.csv          # Raw government dataset
│
├── sql/
│   └── SQL_Analysis.sql                   # All SQL: staging + 6 mart tables
│
├── python/
│   └── csj_pipeline.ipynb                 # Data processing + ML forecast + Excel export
│
├── output/
│   ├── tableau_ridings_long.csv           # Tableau-ready: constituency trends + 2026 forecast
│   ├── tableau_orgs_top30_long.csv        # Tableau-ready: TOP 30 organisations per constituency
│   ├── tableau_all_orgs_full.csv          # Full organisation dataset
│   └── CSJ_Analysis_Output.xlsx          # Formatted Excel delivery (6 sheets + forecast)
│
├── report/
│   └── YRES_CSJ_Analysis_Report.docx     # Executive report with insights & recommendations
│
└── README.md
```

---

## SQL Layer — Key Techniques

### 1. Multi-Layer Architecture (raw → staging → mart)
```sql
-- Staging: standardise BC province name
CREATE TABLE stg_csj AS
SELECT
    raw_year AS year,
    CASE WHEN raw_region LIKE '%British Columbia%'
         THEN 'British Columbia' ELSE raw_region END AS region,
    TRIM(raw_constituency)  AS constituency,
    UPPER(TRIM(raw_org_name)) AS org_name,
    raw_amount AS amount,
    raw_jobs   AS jobs
FROM raw_csj;
```

### 2. Conditional Aggregation — Long to Wide Pivot
```sql
-- Mart: constituency-level summary (one row per riding, years as columns)
SELECT
    constituency,
    COUNT(DISTINCT org_name) AS total_number_of_organizations,
    SUM(CASE WHEN year = 2017 THEN amount ELSE 0 END) AS funding_2017,
    SUM(CASE WHEN year = 2017 THEN jobs   ELSE 0 END) AS jobs_2017,
    SUM(CASE WHEN year = 2017 THEN amount ELSE 0 END) /
        NULLIF(SUM(CASE WHEN year = 2017 THEN jobs ELSE 0 END), 0) AS avg_salary_2017,
    -- ... repeated for 2018–2025
FROM stg_csj
WHERE region = 'Ontario'
GROUP BY constituency
ORDER BY constituency;
```

### 3. CTE + Window Function — TOP 30 Organisations per Constituency
```sql
-- Mart: top 30 job-creating organisations per constituency
CREATE TABLE mart_on_organizations AS
WITH cte_base AS (
    SELECT
        constituency,
        org_name,
        SUM(jobs) AS total_jobs_created,
        SUM(CASE WHEN year = 2017 THEN amount ELSE 0 END) AS funding_2017,
        -- ... 2017–2025 columns
    FROM stg_csj
    WHERE region = 'Ontario'
    GROUP BY constituency, org_name
),
cte_ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY constituency
            ORDER BY total_jobs_created DESC
        ) AS rn
    FROM cte_base
)
SELECT constituency, org_name, funding_2017, jobs_2017, avg_salary_2017 -- ...
FROM cte_ranked
WHERE rn < 31;
```

---

## Python Layer — Key Steps

### 1. EDA & Data Quality Checks
```python
# NULL check
SELECT COUNT(*) - COUNT(year) AS null_year, ... FROM raw_csj;

# Duplicate check (business logic: same org can receive multiple grants/year)
SELECT year, constituency, org_name, COUNT(*) AS duplicate_count
FROM raw_csj
GROUP BY year, constituency, org_name
HAVING COUNT(*) > 1;

# Anomaly check: amount = 0 with jobs > 0 (retained with documentation)
SELECT * FROM raw_csj WHERE amount = 0;
```

### 2. Wide → Long Transformation for Tableau
```python
# Melt wide table to long format
all_ridings_long = pd.melt(
    all_ridings,
    id_vars=['constituency', 'province', 'total_number_of_organizations'],
    var_name='metric_year',
    value_name='value'
)

# Split metric_year into metric + year
all_ridings_long[['metric', 'year']] = \
    all_ridings_long['metric_year'].str.rsplit('_', n=1, expand=True)

# Pivot back: funding / jobs / avg_salary as separate columns
all_ridings_long = all_ridings_long.pivot_table(
    index=['constituency', 'province', 'total_number_of_organizations', 'year'],
    columns='metric',
    values='value'
).reset_index()
```

### 3. Linear Regression Forecast (2026)
```python
from sklearn.linear_model import LinearRegression

results = []
for (region, constituency), group in constituency_yearly.groupby(['region', 'constituency']):
    X = group[['year']]
    y = group['total_funding']

    model = LinearRegression().fit(X, y)
    pred  = model.predict([[2026]])[0]

    results.append({
        'region':            region,
        'constituency':      constituency,
        'pred_funding_2026': round(max(pred, 0))
    })

predictions = pd.DataFrame(results)
```
> **Model choice rationale:** Linear Regression was selected intentionally. With only 9 annual data points per constituency, complex models (Random Forest, neural networks) would overfit. Linear Regression provides stable, interpretable trend-based forecasts appropriate for this data volume.

---

## Tableau Dashboards

| Dashboard | Chart Type | Business Question |
|-----------|-----------|-------------------|
| Provincial Funding Trend | Line chart (2017–2026 incl. forecast) | How is CSJ funding trending per province? |
| Jobs Created Trend | Line chart | Is job creation tracking with funding? |
| Average Salary Trend | Line chart | Is CSJ purchasing power declining? |
| Constituency Quadrant | Scatter plot + median reference lines | Which constituencies are stars vs. high-potential? |
| Job Efficiency | Scatter plot | Where does each dollar create the most jobs? |
| Fastest-Growing Constituencies | Horizontal bar chart (TOP 15) | Where is CSJ market expanding fastest? |
| Competitor Heatmap | Heatmap (org × year) | Which organisations consistently dominate funding? |

---

## Key Findings

| # | Finding | Insight |
|---|---------|---------|
| 1 | 2021–2022 funding peak was pandemic stimulus, not organic growth | Use 2023–2025 trend as baseline for forecasting |
| 2 | Alberta creates more jobs per dollar than BC, gap widening since 2021 | Alberta offers better cost efficiency for YRES expansion |
| 3 | Average salary rising faster than funding in Ontario (2024–2025) | CSJ purchasing power is declining; update grant salary assumptions |
| 4 | Calgary Confederation is a clear outlier — funding and jobs dominant | Saturated market; enter through adjacent constituencies |
| 5 | Kenora leads all 198 constituencies in job efficiency | Low-competition, high-ROI expansion opportunity |
| 6 | Edmonton Manning grew 3.8× from 2017–2025 | Fastest-growing market; first-mover advantage available |
| 7 | Top 3 organisations per constituency control majority of CSJ funding | Monitor competitor funding trends for market entry timing |

---

## Deliverables

- **Excel Report** — 6 formatted sheets (ON/BC/AB ridings + organisations) + 2026 forecast sheet
- **Tableau Dashboards** — 7 interactive charts across 4 dashboards
- **Executive Report** — Strategic insights and 3-horizon recommendations for YRES
- **ML Forecast** — 2026 funding predictions for all 198 constituencies

---

## Data Source

Canada Summer Jobs open dataset — released by Employment and Social Development Canada (ESDC).
Available at: [Open Government Portal](https://open.canada.ca/data/en/dataset/aea0cfff-d26c-4ef4-a47e-3e7b66af0a9c)

---

## Author

**Andi Dong**
McMaster University · MSc Engineering (Automation & Smart Systems)
[LinkedIn](https://linkedin.com/in/andi-dong-a2a1a9390) · [GitHub](https://github.com/GTAZR)
