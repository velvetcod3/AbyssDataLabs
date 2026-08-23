# General Parliamentary & Misc Legislation Feed (UK Parliament)

> Broad-spectrum coverage of general civic, educational, administrative, and unclassified UK parliamentary bills.

## 📊 Dataset Metadata
- **Primary Source:** Official UK Parliament API
- **Enrichment:** Syuzhet Sentiment Scoring & Quanteda Readability Index (Flesch-Kincaid Grade Level)
- **Formats Available:** `.parquet` (Fast Analytical Queries), `.jsonl` (LLM / RAG Pipelines), `.csv` (Spreadsheets)
- **License:** Commercial & Non-Commercial Data Redistribution License

## 🔍 Sample Data Preview (First 5 Rows)

|   id|date                |title                                     | sentiment_score| readability_index|
|----:|:-------------------|:-----------------------------------------|---------------:|-----------------:|
| 4128|2026-08-13 23:00:00 |Commercial Payments Bill [HL]             |            0.80|             16.22|
| 4030|2026-08-13 23:00:00 |Railways Bill                             |            0.80|             15.80|
| 4127|2026-08-03 23:00:00 |Sporting Events Bill [HL]                 |            0.80|             15.43|
| 4123|2026-08-03 23:00:00 |Steel Industry (Nationalisation) Act 2026 |            0.80|             18.68|
| 4142|2026-07-23 23:00:00 |Creative Education Access Bill [HL]       |            1.55|             17.94|

## ⚡ Quickstart Code (R Example)

```r
library(arrow)
library(dplyr)

# Load high-speed Parquet dataset
df <- read_parquet("other_general_feed.parquet")

# Example: Filtering domain specific legislation
general_bills <- df %>%
  select(title, date, sentiment_score, readability_index)
```

## 🛒 Commercial Licensing & Access

This GitHub repository serves as a **free developer preview**.

- **Full Static Dataset (£199):** Instant download via [OpenDataBay Purchase Link](https://opendatabay.com)
- **Weekly Auto-Update Feed (£99/mo):** Automated delivery of fresh weekly updates formatted for live production RAG models.
- **Custom Extraction Requests:** Need deeper historical backfills or Statutory Instruments included? Contact our data engineering team via GitHub Issues or Direct Message.

