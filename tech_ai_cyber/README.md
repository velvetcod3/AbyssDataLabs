# Tech, AI & Cybersecurity Policy Feed (UK Parliament)

> Structured tracking of artificial intelligence governance, data protection, cyber security, and digital infrastructure bills.

## 📊 Dataset Metadata
- **Primary Source:** Official UK Parliament API
- **Enrichment:** Syuzhet Sentiment Scoring & Quanteda Readability Index (Flesch-Kincaid Grade Level)
- **Formats Available:** `.parquet` (Fast Analytical Queries), `.jsonl` (LLM / RAG Pipelines), `.csv` (Spreadsheets)
- **License:** Commercial & Non-Commercial Data Redistribution License

## 🔍 Sample Data Preview (First 5 Rows)

|   id|date                |title                                                                | sentiment_score| readability_index|
|----:|:-------------------|:--------------------------------------------------------------------|---------------:|-----------------:|
| 4035|2026-08-13 23:00:00 |Cyber Security and Resilience (Network and Information Systems) Bill |            1.20|             19.94|
| 4269|2026-07-15 23:00:00 |Energy and Digital Infrastructure (Planning) Bill                    |            1.05|             18.80|
| 4187|2026-06-22 23:00:00 |Telecommunications (Fixed-term Contracts) Bill                       |            0.80|             18.68|
| 4170|2026-06-17 23:00:00 |Automated Online Software (Access and Transparency) Bill             |            0.80|             18.96|
| 4086|2026-05-04 23:00:00 |Online Services (Age Restrictions) Bill                              |            0.80|             17.20|

## ⚡ Quickstart Code (R Example)

```r
library(arrow)
library(dplyr)

# Load high-speed Parquet dataset
df <- read_parquet("tech_ai_cyber_feed.parquet")

# Example: Filtering domain specific legislation
ai_bills <- df %>%
  filter(str_detect(clean_text, "artificial intelligence|cyber")) %>%
  select(title, sentiment_score, readability_index)
```

## 🛒 Commercial Licensing & Access

This GitHub repository serves as a **free developer preview**.

- **Full Static Dataset (£199):** Instant download via [OpenDataBay Purchase Link](https://opendatabay.com)
- **Weekly Auto-Update Feed (£99/mo):** Automated delivery of fresh weekly updates formatted for live production RAG models.
- **Custom Extraction Requests:** Need deeper historical backfills or Statutory Instruments included? Contact our data engineering team via GitHub Issues or Direct Message.

