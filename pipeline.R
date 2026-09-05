library(dplyr)
library(stringr)
library(httr)
library(jsonlite)
library(tibble)
library(syuzhet)
library(quanteda)
library(quanteda.textstats)
library(arrow)
library(readr)

# ==========================================
# 1. FETCH BASE BILL LIST & IDs (WITH PAGINATION)
# ==========================================

all_items <- list()
skip_val <- 0
take_val <- 100      # Request 100 records per page
max_records <- 4000  # Cap limit

cat("Fetching base bill list from UK Parliament API via pagination...\n")

repeat {
  list_url <- paste0("https://bills-api.parliament.uk/api/v1/Bills?skip=", skip_val, "&take=", take_val)
  
  response <- GET(list_url, user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) OpendatabayResearchBot/1.0"))
  
  if (status_code(response) != 200) {
    cat("Warning: Request failed or reached end at skip =", skip_val, "with status code:", status_code(response), "\n")
    break
  }
  
  raw_content <- content(response, as = "text", encoding = "utf-8")
  raw_data <- fromJSON(raw_content, flatten = TRUE)
  items <- if("items" %in% names(raw_data)) raw_data$items else raw_data
  
  if (is.null(items) || length(items) == 0 || nrow(items) == 0) {
    break
  }
  
  all_items[[length(all_items) + 1]] <- items
  cat("Fetched batch up to skip:", skip_val, "| Records in batch:", nrow(items), "\n")
  
  skip_val <- skip_val + take_val
  
  if (skip_val >= max_records || nrow(items) < take_val) {
    break
  }
  
  Sys.sleep(0.3)
}

if (length(all_items) > 0) {
  raw_items_df <- do.call(rbind, all_items)
  if (nrow(raw_items_df) > max_records) {
    raw_items_df <- head(raw_items_df, max_records)
  }
} else {
  raw_items_df <- data.frame()
}

cat("Total base bills targeted for detail enrichment:", nrow(raw_items_df), "\n")

# ==========================================
# 2. SAFE BATCH DETAIL EXTRACTION LOOP
# ==========================================
cat("Starting safe batch fetching of bill summaries and descriptions...\n\n")

bill_ids <- if("billId" %in% names(raw_items_df)) raw_items_df$billId else raw_items_df$id

total_records <- length(bill_ids)
detailed_records_list <- vector("list", total_records)

pb <- txtProgressBar(min = 0, max = total_records, style = 3)

for (i in seq_along(bill_ids)) {
  current_id <- bill_ids[i]
  detail_url <- paste0("https://services.parliament.uk/api/v1/Bills/", current_id)
  
  detail_res <- tryCatch({
    GET(detail_url, timeout(10))
  }, error = function(e) {
    NULL
  })
  
  # Safe defaults ensure NO bills are deleted due to missing details
  summary_text <- "No summary available"
  description_text <- "No description available"
  
  if (!is.null(detail_res) && status_code(detail_res) == 200) {
    detail_content <- content(detail_res, as = "text", encoding = "utf-8")
    detail_json <- tryCatch({
      fromJSON(detail_content, flatten = TRUE)
    }, error = function(e) {
      NULL
    })
    
    if (!is.null(detail_json)) {
      if ("summary" %in% names(detail_json) && !is.null(detail_json$summary) && detail_json$summary != "") {
        summary_text <- as.character(detail_json$summary)
      }
      if ("description" %in% names(detail_json) && !is.null(detail_json$description) && detail_json$description != "") {
        description_text <- as.character(detail_json$description)
      }
    }
  }
  
  base_row <- raw_items_df[i, ]
  bill_title <- if("shortTitle" %in% names(base_row)) base_row$shortTitle else base_row$title
  bill_date <- if("lastUpdate" %in% names(base_row)) base_row$lastUpdate else base_row$date
  
  # Construct unified structural text block
  final_text <- paste(
    "Title:", bill_title,
    "| Summary:", summary_text,
    "| Description:", description_text
  )
  
  detailed_records_list[[i]] <- tibble(
    id = as.character(current_id),
    date = as.character(bill_date),
    title = as.character(bill_title),
    clean_text = as.character(final_text),
    corpus_source = "UK_Parliament_Bills_Enriched_Corpus"
  )
  
  setTxtProgressBar(pb, i)
  Sys.sleep(0.2)
}

close(pb)
cat("\nBatch fetching completed successfully!\n")

clean_corpus <- bind_rows(detailed_records_list)

# ==========================================
# 3. SANITIZATION, DEDUPLICATION & NLP ENRICHMENT
# ==========================================
cat("Running deduplication, text sanitization, and NLP enrichment...\n")

clean_corpus <- clean_corpus %>%
  filter(!is.na(title) & title != "") %>%
  mutate(
    date = as.POSIXct(date),
    title = str_replace_all(title, "[\r\n\t]", " "),
    title = str_squish(title),
    clean_text = str_replace_all(clean_text, "[\r\n\t]", " "),
    clean_text = str_squish(clean_text)
  ) %>%
  arrange(desc(date)) %>%             # Sort by newest date first
  distinct(title, .keep_all = TRUE)   # Keep most recent unique entry per title

cat(" -> Unique deduplicated record count:", nrow(clean_corpus), "\n")

# Calculate Sentiment Scores via Syuzhet Lexicon
cat(" -> Computing Syuzhet sentiment scores...\n")
clean_corpus <- clean_corpus %>%
  mutate(
    sentiment_score = round(get_sentiment(clean_text, method = "syuzhet"), 3)
  )

# Calculate Readability via Quanteda (Flesch-Kincaid Grade Level)
cat(" -> Computing Flesch-Kincaid readability indices...\n")
corp <- corpus(clean_corpus, text_field = "clean_text")
readability_res <- textstat_readability(corp, measure = "Flesch.Kincaid")

clean_corpus <- clean_corpus %>%
  mutate(
    readability_index = round(readability_res$Flesch.Kincaid, 2)
  )

cat(" -> Enriched dataset ready!\n")

# ==========================================
# 4. MASTER EXPORT (PARQUET & JSONL)
# ==========================================
cat("Exporting master corpus files...\n")

# Master JSONL
con <- file("uk_parliament_master_enriched.jsonl", open = "w")
for(i in seq_len(nrow(clean_corpus))) {
  writeLines(jsonlite::toJSON(subfeed_df[k, ], auto_unbox = TRUE, collapse = ""), con_sec)
}
close(con)

# Master Parquet
arrow::write_parquet(clean_corpus, "uk_parliament_master_enriched.parquet")

cat(" -> Master files exported successfully!\n")

# ==========================================
# 5. SUBSECTOR SPLITTER WITH CATCH-ALL "OTHER"
# ==========================================
cat("\nSplitting corpus into sector feeds & generating GitHub sample CSVs...\n")

# Vector to track all bill IDs that get classified into a sector
assigned_ids <- character(0)

export_sector_subfeed <- function(data, sector_name, keyword_regex) {
  
  subfeed_df <- data %>%
    filter(str_detect(str_to_lower(clean_text), keyword_regex))
  
  if(nrow(subfeed_df) == 0) {
    cat(paste0(" -> Warning: 0 records found for sector: ", sector_name, "\n"))
    return(NULL)
  }
  
  # Track assigned IDs globally
  assigned_ids <<- c(assigned_ids, subfeed_df$id)
  
  # Create directory
  dir.create(sector_name, showWarnings = FALSE)
  
  # Export Files (.parquet, .jsonl, .csv, 5-row sample)
  arrow::write_parquet(subfeed_df, file.path(sector_name, paste0(sector_name, "_feed.parquet")))
  
  con_sec <- file(file.path(sector_name, paste0(sector_name, "_feed.jsonl")), open = "w")
  for(k in seq_len(nrow(subfeed_df))) {
    writeLines(jsonlite::toJSON(subfeed_df[k, ], auto_unbox = TRUE), con_sec)
  }
  close(con_sec)
  
  readr::write_csv(subfeed_df, file.path(sector_name, paste0(sector_name, "_feed.csv")))
  readr::write_csv(head(subfeed_df, 5), file.path(sector_name, paste0(sector_name, "_sample_5rows.csv")))
  
  cat(paste0(" -> [", sector_name, "] Exported ", nrow(subfeed_df), " unique rows + 5-row sample CSV.\n"))
}

# 1. Run exports for your 6 primary target sectors (with tightened regex)
export_sector_subfeed(clean_corpus, "defense_procurement", 
                      "\\bdefence\\b|\\bdefense\\b|\\bmilitary\\b|\\barmed forces\\b|\\bministry of defence\\b|procurement")

export_sector_subfeed(clean_corpus, "healthcare_nhs", 
                      "\\bnhs\\b|healthcare|pharma|medical|\\bhealth\\b|hospital")

export_sector_subfeed(clean_corpus, "tech_ai_cyber", 
                      "artificial intelligence|\\bai\\b|cyber|data protection|digital|online|telecommunications")

export_sector_subfeed(clean_corpus, "legal_statutory", 
                      "statutory|amendment|court|regulation|judiciary|tribunal|legislation")

export_sector_subfeed(clean_corpus, "energy_climate", 
                      "energy|net zero|climate|carbon|offshore|electricity|renewable")

export_sector_subfeed(clean_corpus, "finance_taxation", 
                      "treasury|\\btax\\b|taxation|banking|\\bfca\\b|financial services|revenue")


# 2. CATCH-ALL: Process unclassified records into "other_general"
unassigned_df <- clean_corpus %>%
  filter(!id %in% unique(assigned_ids))

if (nrow(unassigned_df) > 0) {
  sector_name <- "other_general"
  dir.create(sector_name, showWarnings = FALSE)
  
  arrow::write_parquet(unassigned_df, file.path(sector_name, paste0(sector_name, "_feed.parquet")))
  
  con_sec <- file(file.path(sector_name, paste0(sector_name, "_feed.jsonl")), open = "w")
  for(k in seq_len(nrow(unassigned_df))) {
    writeLines(jsonlite::toJSON(unassigned_df[k, ], auto_unbox = TRUE), con_sec)
  }
  close(con_sec)
  
  readr::write_csv(unassigned_df, file.path(sector_name, paste0(sector_name, "_feed.csv")))
  readr::write_csv(head(unassigned_df, 5), file.path(sector_name, paste0(sector_name, "_sample_5rows.csv")))
  
  cat(paste0(" -> [other_general] Exported ", nrow(unassigned_df), " unclassified rows + 5-row sample CSV.\n"))
} else {
  cat(" -> All records were successfully classified into sectors!\n")
}

# ==========================================
# 6. VERIFY SAMPLE PREVIEW OUTPUT
# ==========================================
sample_preview <- read_csv("defense_procurement/defense_procurement_sample_5rows.csv")

sample_preview %>%
  select(id, date, title, sentiment_score, readability_index) %>%
  print(width = Inf)

library(readr)
library(dplyr)

# Define your 6 target subsectors
sectors <- c(
  "defense_procurement", 
  "healthcare_nhs", 
  "tech_ai_cyber", 
  "legal_statutory", 
  "energy_climate", 
  "finance_taxation"
)

# Run a loop to print out 2 sample rows from each sector directory
for (sec in sectors) {
  sample_path <- file.path(sec, paste0(sec, "_sample_5rows.csv"))
  
  cat("\n=======================================================\n")
  cat("SUBSECTOR:", toupper(sec), "\n")
  cat("=======================================================\n")
  
  if (file.exists(sample_path)) {
    df_sample <- read_csv(sample_path, show_col_types = FALSE)
    
    cat("Total sample rows found:", nrow(df_sample), "\n\n")
    
    # Print Title, Sentiment, Readability, and a snippet of the clean_text
    df_sample %>%
      head(2) %>%
      select(title, sentiment_score, readability_index, clean_text) %>%
      mutate(clean_text_snippet = substr(clean_text, 1, 100)) %>%
      select(title, sentiment_score, readability_index, clean_text_snippet) %>%
      print(width = Inf)
  } else {
    cat("❌ File NOT found:", sample_path, "\n")
  }
}
