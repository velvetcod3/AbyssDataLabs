# Healthcare & NHS Regulatory Data Feed (UK Parliament)

> Pre-scored statutory updates covering NHS operations, pharmaceutical compliance, and medical device regulations.

## 📊 Dataset Metadata
- **Primary Source:** Official UK Parliament API
- **Enrichment:** Syuzhet Sentiment Scoring & Quanteda Readability Index (Flesch-Kincaid Grade Level)
- **Formats Available:** `.parquet` (Fast Analytical Queries), `.jsonl` (LLM / RAG Pipelines), `.csv` (Spreadsheets)
- **License:** Commercial & Non-Commercial Data Redistribution License

## 🔍 Sample Data Preview (First 5 Rows)

|   id|date                |title                                                                                          | sentiment_score| readability_index|
|----:|:-------------------|:----------------------------------------------------------------------------------------------|---------------:|-----------------:|
| 4124|2026-07-19 23:00:00 |Health Bill                                                                                    |             0.8|             14.90|
| 4272|2026-07-15 23:00:00 |General Medical Council (Fitness to Practise) Rules (Amendment) Bill                           |             2.2|             18.17|
| 4149|2026-07-05 23:00:00 |Mental Health Support (Sentence of Detention and Imprisonment for Public Protection) Bill [HL] |             1.1|             18.35|
| 4257|2026-07-01 23:00:00 |Medical Services (Rural Areas) Bill                                                            |             0.8|             18.68|
| 4233|2026-06-24 23:00:00 |Health Insurance (Exemption from Insurance Premium Tax) Bill                                   |             0.3|             17.90|

## ⚡ Quickstart Code (R Example)

```r
library(arrow)
library(dplyr)

# Load high-speed Parquet dataset
df <- read_parquet("healthcare_nhs_feed.parquet")

# Example: Filtering domain specific legislation
health_bills <- df %>%
  filter(str_detect(clean_text, "nhs|medical|pharma")) %>%
  select(title, sentiment_score, readability_index)
```

## 🛒 Commercial Licensing & Access

This GitHub repository serves as a **free developer preview**.

- **Full Static Dataset (£199):** Instant download via [OpenDataBay Purchase Link](https://opendatabay.com)
- **Weekly Auto-Update Feed (£99/mo):** Automated delivery of fresh weekly updates formatted for live production RAG models.
- **Custom Extraction Requests:** Need deeper historical backfills or Statutory Instruments included? Contact our data engineering team via GitHub Issues or Direct Message.

