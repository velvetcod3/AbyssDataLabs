# Finance, Treasury & Taxation Feed (UK Parliament)

> High-frequency tracking of Treasury bills, FCA regulatory shifts, banking reforms, and revenue legislation.

## 📊 Dataset Metadata
- **Primary Source:** Official UK Parliament API
- **Enrichment:** Syuzhet Sentiment Scoring & Quanteda Readability Index (Flesch-Kincaid Grade Level)
- **Formats Available:** `.parquet` (Fast Analytical Queries), `.jsonl` (LLM / RAG Pipelines), `.csv` (Spreadsheets)
- **License:** Commercial & Non-Commercial Data Redistribution License

## 🔍 Sample Data Preview (First 5 Rows)

|   id|date                |title                                                          | sentiment_score| readability_index|
|----:|:-------------------|:--------------------------------------------------------------|---------------:|-----------------:|
| 4129|2026-08-13 23:00:00 |Financial Services and Markets Bill [HL]                       |            0.90|             16.72|
| 4207|2026-07-19 23:00:00 |Taxation (Energy and Vehicles) Act 2026                        |            0.80|             17.42|
| 4225|2026-06-24 23:00:00 |Children’s Clothing (Value Added Tax) Bill                     |            0.55|             16.03|
| 4229|2026-06-24 23:00:00 |Domestic Energy (Value Added Tax) Bill                         |            0.30|             17.42|
| 4230|2026-06-24 23:00:00 |Exemption from Value Added Tax (Listed Places of Worship) Bill |            0.55|             16.76|

## ⚡ Quickstart Code (R Example)

```r
library(arrow)
library(dplyr)

# Load high-speed Parquet dataset
df <- read_parquet("finance_taxation_feed.parquet")

# Example: Filtering domain specific legislation
finance_trends <- df %>%
  arrange(desc(date)) %>%
  select(title, sentiment_score, readability_index)
```

## 🛒 Commercial Licensing & Access

This GitHub repository serves as a **free developer preview**.

- **Full Static Dataset (£199):** Instant download via [OpenDataBay Purchase Link](https://opendatabay.com)
- **Weekly Auto-Update Feed (£99/mo):** Automated delivery of fresh weekly updates formatted for live production RAG models.
- **Custom Extraction Requests:** Need deeper historical backfills or Statutory Instruments included? Contact our data engineering team via GitHub Issues or Direct Message.

