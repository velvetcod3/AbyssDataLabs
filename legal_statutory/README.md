# Legal & Statutory Amendments Feed (UK Parliament)

> Indexing court reforms, statutory instruments, and judicial amendments with pre-calculated legalese readability metrics.

## 📊 Dataset Metadata
- **Primary Source:** Official UK Parliament API
- **Enrichment:** Syuzhet Sentiment Scoring & Quanteda Readability Index (Flesch-Kincaid Grade Level)
- **Formats Available:** `.parquet` (Fast Analytical Queries), `.jsonl` (LLM / RAG Pipelines), `.csv` (Spreadsheets)
- **License:** Commercial & Non-Commercial Data Redistribution License

## 🔍 Sample Data Preview (First 5 Rows)

|   id|date                |title                                                                | sentiment_score| readability_index|
|----:|:-------------------|:--------------------------------------------------------------------|---------------:|-----------------:|
| 4267|2026-07-19 23:00:00 |Freedom of Information Act 2000 (Amendment) Bill                     |            1.95|             17.00|
| 4272|2026-07-15 23:00:00 |General Medical Council (Fitness to Practise) Rules (Amendment) Bill |            2.20|             18.17|
| 4268|2026-07-15 23:00:00 |Hunting Act 2004 (Amendment) Bill                                    |            0.55|             15.73|
| 4255|2026-06-29 23:00:00 |Water Regulation Bill                                                |            0.80|             17.68|
| 4083|2026-06-28 23:00:00 |Courts and Tribunals Bill                                            |            0.80|             15.43|

## ⚡ Quickstart Code (R Example)

```r
library(arrow)
library(dplyr)

# Load high-speed Parquet dataset
df <- read_parquet("legal_statutory_feed.parquet")

# Example: Filtering domain specific legislation
legal_bills <- df %>%
  filter(readability_index > 16) %>%
  select(title, sentiment_score, readability_index)
```

## 🛒 Commercial Licensing & Access

This GitHub repository serves as a **free developer preview**.

- **Full Static Dataset (£199):** Instant download via [OpenDataBay Purchase Link](https://opendatabay.com)
- **Weekly Auto-Update Feed (£99/mo):** Automated delivery of fresh weekly updates formatted for live production RAG models.
- **Custom Extraction Requests:** Need deeper historical backfills or Statutory Instruments included? Contact our data engineering team via GitHub Issues or Direct Message.

