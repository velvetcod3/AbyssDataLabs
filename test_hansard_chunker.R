library(httr)
library(jsonlite)
library(dplyr)
library(stringr)

# ==========================================
# 1. SLIDING WINDOW CHUNKER FUNCTION
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
# 2. LOCAL VERIFICATION TESTS
# ==========================================
sample_transcript <- "Mr. Speaker, the national health service requires urgent structural investment regarding AI diagnostics and primary care infrastructure. We have seen significant delays in regional clinic deployment across the North West..."

# Single-chunk check (Short speech)
short_speech <- paste(rep(sample_transcript, 8), collapse = " ")
short_chunks <- chunk_text_window(short_speech, chunk_size = 300, overlap = 50)

cat("--- Short Speech Check ---\n")
cat("Word Count:", length(str_split(short_speech, "\\s+")[[1]]), "\n")
cat("Generated Chunks:", length(short_chunks), "\n\n")

# Multi-chunk check (Long debate speech)
long_test_speech <- paste(rep(sample_transcript, 30), collapse = " ")
multi_chunks <- chunk_text_window(long_test_speech, chunk_size = 300, overlap = 50)

cat("--- Long Speech Multi-Chunk Check ---\n")
cat("Total Words:", length(str_split(long_test_speech, "\\s+")[[1]]), "\n")
cat("Generated Chunks:", length(multi_chunks), "\n")
cat("Sample Chunk 1 Snippet:", substr(multi_chunks[[1]], 1, 120), "...\n")
cat("Sample Chunk 2 Snippet:", substr(multi_chunks[[2]], 1, 120), "...\n")
