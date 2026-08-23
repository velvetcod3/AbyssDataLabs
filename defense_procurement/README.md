# Defense Procurement & MoD Policy Feed (UK Parliament)

> Quantitative tracking of UK Ministry of Defence legislation, procurement mandates, and military supply chain reforms.

## 📊 Dataset Metadata
- **Primary Source:** Official UK Parliament API
- **Enrichment:** Syuzhet Sentiment Scoring & Quanteda Readability Index (Flesch-Kincaid Grade Level)
- **Formats Available:** `.parquet` (Fast Analytical Queries), `.jsonl` (LLM / RAG Pipelines), `.csv` (Spreadsheets)
- **License:** Commercial & Non-Commercial Data Redistribution License

## 🔍 Sample Data Preview (First 5 Rows)

|   id|date                |title                                                           | sentiment_score| readability_index|
|----:|:-------------------|:---------------------------------------------------------------|---------------:|-----------------:|
| 4065|2026-08-13 23:00:00 |Armed Forces Bill                                               |            0.80|             15.16|
| 4260|2026-07-19 23:00:00 |Public Procurement (British Goods and Services) Bill            |            1.40|             17.00|
| 4098|2026-05-05 23:00:00 |United States Military and Security Operations (Oversight) Bill |            0.80|             21.01|
| 3951|2026-05-04 23:00:00 |Food Products (Market Regulation and Public Procurement) Bill   |            1.20|             17.90|
| 3795|2026-05-04 23:00:00 |Military Action Bill                                            |            1.05|             17.68|

## ⚡ Quickstart Code (R Example)

```r
library(arrow)
library(dplyr)

# Load high-speed Parquet dataset
df <- read_parquet("defense_procurement_feed.parquet")

# Example: Filtering domain specific legislation
defense_bills <- df %>%
  filter(str_detect(clean_text, "procurement|equipment")) %>%
  select(title, sentiment_score, readability_index)
```

## 🛒 Commercial Licensing & Access

This GitHub repository serves as a **free developer preview**.

- **Full Static Dataset (£199):** Instant download via [OpenDataBay Purchase Link](https://opendatabay.com)
- **Weekly Auto-Update Feed (£99/mo):** Automated delivery of fresh weekly updates formatted for live production RAG models.
- **Custom Extraction Requests:** Need deeper historical backfills or Statutory Instruments included? Contact our data engineering team via GitHub Issues or Direct Message.

