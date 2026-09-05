library(httr)
library(httr2)
library(xml2)
library(dplyr)
library(stringr)
library(jsonlite)
library(arrow)

# The script will naturally pull the secret provided by GitHub Actions or local .Renviron
api_key <- Sys.getenv("OPENAI_API_KEY")

# ==========================================
# 1. PARLIAMENTARY TEXT CLEANER (NEW)
# ==========================================
# Removes honorifics that trigger false positive classification & embedding noise
clean_parliamentary_text <- function(text) {
  text <- str_replace_all(text, "(?i)hon\\.\\s+(and\\s+)?gallant\\s+Member", "Member")
  text <- str_replace_all(text, "(?i)hon\\.\\s+(and\\s+)?learned\\s+Member", "Member")
  text <- str_replace_all(text, "(?i)right\\s+hon\\.", "")
  return(str_squish(text))
}

# ==========================================
# 2. UPGRADED 3-STAGE SECTOR CLASSIFIER
# ==========================================
tag_sector_robust <- function(text, debate_title = "") {
  text_clean  <- str_to_lower(text)
  title_clean <- str_to_lower(debate_title)
  
  # Stage 1: Parent Debate Title Context Override
  if (grepl("defence|defense|military|armed forces|weapons|ukraine|nato|procurement", title_clean)) return("defense_procurement")
  if (grepl("energy|climate|net zero|wind|solar|electricity|oil|gas|grid|carbon", title_clean)) return("energy_climate")
  if (grepl("finance|tax|taxation|treasury|budget|economy|fiscal|banking|monetary", title_clean)) return("finance_taxation")
  if (grepl("health|nhs|hospital|infant|childcare|sure start|maternity|medicine|patient", title_clean)) return("healthcare_nhs")
  if (grepl("tech|artificial intelligence|cyber|broadband|semiconductor|data|digital", title_clean)) return("tech_ai_cyber")
  
  # Stage 2: Phrase Anchoring + Negative Exclusion Matrix
  # Defense
  if (grepl("ministry of defence|armed forces|military personnel|defence procurement|defence committee|royal navy|royal air force|veterans|weapons systems", text_clean) && 
      !grepl("defenceless|vulnerable children|defenceless babies|defence lawyer", text_clean)) {
    return("defense_procurement")
  }
  
  # Energy
  if (grepl("net zero|renewable energy|carbon emissions|offshore wind|electricity grid|energy bills|fossil fuels|nuclear power", text_clean) && 
      !grepl("plumbing|kinship|parenting|family hub|screen time", text_clean)) {
    return("energy_climate")
  }
  
  # Finance (Updated with politeness & charity exclusions)
  if (grepl("treasury|corporation tax|value added tax|capital gains|fiscal policy|bank of england|national insurance|tax evasion|donations", text_clean) && 
      !grepl("taxing time|emotional investment|paying tribute|tribute to|baby equipment|church|charity", text_clean)) {
    return("finance_taxation")
  }
  
  # Healthcare
  if (grepl("nhs|infant support|sure start|midwives|health visitors|1001 critical days|general practitioner|mental health|childcare|maternity", text_clean)) {
    return("healthcare_nhs")
  }
  
  # Tech
  if (grepl("artificial intelligence|generative ai|cybersecurity|data protection|broadband infrastructure|semiconductors|tech sector|online safety", text_clean) && 
      !grepl("online services|driven online", text_clean)) {
    return("tech_ai_cyber")
  }
  
  # Legal
  if (grepl("standing order|statutory duty|secondary legislation|clause [0-9]|statute book|royal assent", text_clean) && 
      !grepl("baby|infant|childcare|sure start", text_clean)) {
    return("legal_statutory")
  }
  
  return("other_general")
}

# ==========================================
# 3. SLIDING WINDOW CHUNKER FUNCTION
# ==========================================
chunk_text_window <- function(text, chunk_size = 300, overlap = 50) {
  words <- str_split(text, "\\s+")[[1]]
  if (length(words) == 0 || is.na(text) || text == "") return(list())
  if (length(words) <= chunk_size) return(list(text))
  
  chunks <- list()
  start <- 1
  while (start <= length(words)) {
    end <- min(start + chunk_size - 1, length(words))
    chunks[[length(chunks) + 1]] <- paste(words[start:end], collapse = " ")
    if (end == length(words)) break
    start <- start + (chunk_size - overlap)
  }
  return(chunks)
}

# ==========================================
# 4. UPGRADED HANSARD INGESTION ENGINE
# ==========================================
fetch_and_chunk_daily_hansard <- function(file_url, debate_date) {
  temp_file <- tempfile(fileext = ".xml")
  
  download.file(file_url, destfile = temp_file, quiet = TRUE)
  doc <- read_xml(temp_file)
  
  speeches <- xml_find_all(doc, "//speech")
  processed_records <- list()
  
  for (i in seq_along(speeches)) {
    speech_node <- speeches[[i]]
    
    # Extract raw text and scrub parliamentary honorifics FIRST
    speech_text_raw <- str_trim(xml_text(speech_node))
    speech_text <- clean_parliamentary_text(speech_text_raw)
    
    # Skip short noise
    if (nchar(speech_text) < 30) next
    
    # --- FIXED ANCESTOR & PRECEDING HEADING EXTRACTION ---
    # Look for ancestor headings first; fallback to preceding headings if absent
    major_heading <- xml_text(xml_find_first(speech_node, "ancestor::major-heading | preceding::major-heading[1]"))
    minor_heading <- xml_text(xml_find_first(speech_node, "ancestor::minor-heading | preceding::minor-heading[1]"))
    
    debate_title <- paste(
      na.omit(c(major_heading, minor_heading)), 
      collapse = " - "
    )
    # ----------------------------------------------------
    
    # --- PATCHED SPEAKER ATTRIBUTION LOGIC ---
    speaker_name <- as.character(xml_attr(speech_node, "speakername"))
    
    if (is.na(speaker_name) || speaker_name == "" || tolower(speaker_name) == "true") {
      speaker_name <- as.character(xml_attr(speech_node, "nospeaker"))
    }
    
    if (is.na(speaker_name) || speaker_name == "" || tolower(speaker_name) == "true") {
      speaker_name <- "Procedural / Chair"
    }
    # ----------------------------------------
    
    # Tag sector directory using 3-stage robust classifier
    sector_dir <- tag_sector_robust(speech_text, debate_title = debate_title)
    
    # Chunk text window
    text_chunks <- chunk_text_window(speech_text, chunk_size = 300, overlap = 50)
    
    if (length(text_chunks) > 0) {
      for (c_idx in seq_along(text_chunks)) {
        
        # Prepend structural metadata context
        vector_ready_text <- paste0(
          "Date: ", debate_date, 
          " | Speaker: ", speaker_name, 
          " | Sector: ", sector_dir, 
          "\nContent: ", text_chunks[[c_idx]]
        )
        
        processed_records[[length(processed_records) + 1]] <- tibble(
          date = debate_date,
          speaker = speaker_name,
          sector = sector_dir,
          debate_title = ifelse(debate_title == "", "Unspecified Debate", debate_title),
          chunk_id = c_idx,
          total_chunks = length(text_chunks),
          raw_text = text_chunks[[c_idx]],
          vector_ready_text = vector_ready_text
        )
      }
    }
  }
  
  unlink(temp_file)
  return(bind_rows(processed_records))
}

# ==========================================
# 5. DYNAMIC DATE SOLVER
# ==========================================
get_latest_hansard_xml <- function(max_lookback_days = 10) {
  current_date <- Sys.Date()
  
  for (i in 0:max_lookback_days) {
    target_date <- current_date - i
    date_str <- format(target_date, "%Y-%m-%d")
    
    xml_url <- paste0("https://www.theyworkforyou.com/pwdata/scrapedxml/debates/debates", date_str, "a.xml")
    res <- HEAD(xml_url, user_agent("Mozilla/5.0"))
    
    if (status_code(res) == 200) {
      cat(" Found active Hansard XML for date:", date_str, "\n")
      return(list(date = date_str, url = xml_url))
    }
  }
  
  cat("❌ Could not find a published Hansard feed within the lookback window.\n")
  return(NULL)
}

# ==========================================
# 6. RESILIENT OPENAI EMBEDDING GENERATOR
# ==========================================
generate_openai_embeddings <- function(text_vector, model = "text-embedding-3-small") {
  
  # 1. Fetch Key from Environment
  api_key <- Sys.getenv("OPENAI_API_KEY")
  
  # 2. GUARD CHECK: Halt immediately if the key is missing
  if (api_key == "") {
    stop("❌ OPENAI_API_KEY environment variable is missing! Set it in your .Renviron or GitHub Secrets.")
  }
  
  # 3. Proceed with API Request
  url <- "https://api.openai.com/v1/embeddings"
  
  req <- request(url) %>%
    req_headers(
      "Authorization" = paste("Bearer", api_key),
      "Content-Type"  = "application/json"
    ) %>%
    req_body_json(list(
      model = model,
      input = text_vector
    )) %>%
    req_retry(max_tries = 5, backoff = ~ 2^.x)
  
  resp <- req_perform(req)
  body <- resp_body_json(resp)
  
  embeddings <- lapply(body$data, function(x) unlist(x$embedding))
  return(embeddings)
}

embed_dataset_in_batches <- function(dataset, batch_size = 10) {
  cat("--- Requesting OpenAI Vector Embeddings --- \n")
  total_rows <- nrow(dataset)
  all_embeddings <- list()
  
  for (i in seq(1, total_rows, by = batch_size)) {
    end_idx <- min(i + batch_size - 1, total_rows)
    cat(sprintf("Embedding chunks %d to %d of %d...\n", i, end_idx, total_rows))
    
    batch_texts <- dataset$vector_ready_text[i:end_idx]
    batch_vecs <- generate_openai_embeddings(batch_texts)
    
    all_embeddings <- c(all_embeddings, batch_vecs)
    
    Sys.sleep(0.5)
  }
  
  dataset$embedding <- all_embeddings
  return(dataset)
}

# ==========================================
# 7. EXPORT SECTOR DATASETS TO .PARQUET
# ==========================================
export_to_sector_directories <- function(vectorized_dataset, debate_date) {
  sectors <- unique(vectorized_dataset$sector)
  
  for (sec in sectors) {
    sector_df <- vectorized_dataset %>% filter(sector == sec)
    
    if (!dir.exists(sec)) dir.create(sec, recursive = TRUE)
    
    file_path <- file.path(sec, paste0("hansard_", sec, "_", debate_date, ".parquet"))
    
    write_parquet(sector_df, file_path)
    cat(sprintf(" Saved %d vector records to -> %s\n", nrow(sector_df), file_path))
  }
}

# ==========================================
# 8. EXECUTE END-TO-END PIPELINE (DAILY RUN)
# ==========================================
cat("--- Starting Production Hansard RAG Ingestion Pipeline ---\n")

# Target yesterday's date since Hansard XML is published retroactively
target_date <- as.character(Sys.Date() - 1)

# Check if target_date falls on a weekend; skip if necessary
if (as.POSIXlt(target_date)$wday %in% c(0, 6)) {
  cat("Target date (", target_date, ") is a weekend. Skipping ingestion.\n")
  q(save = "no", status = 0)
}

cat("Executing daily ingestion for target date:", target_date, "\n")

# Fetch all fragments ('a' through 'e') for yesterday's sitting day
suffixes <- c("a", "b", "c", "d", "e", "")
day_chunks <- list()

for (sfx in suffixes) {
  xml_url <- paste0("https://www.theyworkforyou.com/pwdata/scrapedxml/debates/debates", target_date, sfx, ".xml")
  res <- HEAD(xml_url, user_agent("Mozilla/5.0"))
  
  if (status_code(res) == 200) {
    cat(" Processing XML fragment:", xml_url, "\n")
    chunk_df <- fetch_and_chunk_daily_hansard(xml_url, target_date)
    if (nrow(chunk_df) > 0) {
      day_chunks[[length(day_chunks) + 1]] <- chunk_df
    }
  }
}

# Aggregate, Vectorize, and Export
if (length(day_chunks) > 0) {
  daily_dataset <- bind_rows(day_chunks)
  cat(" Ingestion Complete! Total Chunks Aggregated across fragments:", nrow(daily_dataset), "\n")
  
  # Vectorize (Batch size set to 10 for rate limit stability)
  vectorized_dataset <- embed_dataset_in_batches(daily_dataset, batch_size = 10)
  
  # Export sector Parquet files
  export_to_sector_directories(vectorized_dataset, target_date)
  cat(" Pipeline Execution Finished Successfully for", target_date, "!\n")
} else {
  cat(" No Hansard XML files found for date:", target_date, "(House may be in recess).\n")
}
