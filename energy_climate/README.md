# Energy & Climate Net-Zero Feed (UK Parliament)

> Quantitative analysis of UK Net-Zero mandates, carbon taxation, offshore energy permitting, and grid policy.

## 📊 Dataset Metadata
- **Primary Source:** Official UK Parliament API
- **Enrichment:** Syuzhet Sentiment Scoring & Quanteda Readability Index (Flesch-Kincaid Grade Level)
- **Formats Available:** `.parquet` (Fast Analytical Queries), `.jsonl` (LLM / RAG Pipelines), `.csv` (Spreadsheets)
- **License:** Commercial & Non-Commercial Data Redistribution License

## 🔍 Sample Data Preview (First 5 Rows)

|   id|date                |title                                                 | sentiment_score| readability_index|
|----:|:-------------------|:-----------------------------------------------------|---------------:|-----------------:|
| 4207|2026-07-19 23:00:00 |Taxation (Energy and Vehicles) Act 2026               |            0.80|             17.42|
| 4269|2026-07-15 23:00:00 |Energy and Digital Infrastructure (Planning) Bill     |            1.05|             18.80|
| 4229|2026-06-24 23:00:00 |Domestic Energy (Value Added Tax) Bill                |            0.30|             17.42|
| 4185|2026-06-22 23:00:00 |Battery Energy Storage (Planning and Regulation) Bill |            1.05|             18.96|
| 4204|2026-06-22 23:00:00 |Climate Change Act 2008 (Repeal) Bill                 |            0.80|             14.64|

## ⚡ Quickstart Code (R Example)

```r
library(arrow)
library(dplyr)

# Load high-speed Parquet dataset
df <- read_parquet("energy_climate_feed.parquet")

# Example: Filtering domain specific legislation
energy_bills <- df %>%
  filter(str_detect(clean_text, "energy|climate|net zero")) %>%
  select(title, sentiment_score, readability_index)
```

## 🛒 Commercial Licensing & Access

This GitHub repository serves as a **free developer preview**.

- **Full Static Dataset (£199):** Instant download via [OpenDataBay Purchase Link](https://opendatabay.com)
- **Weekly Auto-Update Feed (£99/mo):** Automated delivery of fresh weekly updates formatted for live production RAG models.
- **Custom Extraction Requests:** Need deeper historical backfills or Statutory Instruments included? Contact our data engineering team via GitHub Issues or Direct Message.

