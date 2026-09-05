library(xml2)

# Load raw XML from the feed URL
doc <- read_xml(latest_feed$url)

# Find speeches mentioning "Deputy Chairman of Ways and Means"
matching_nodes <- xml_find_all(doc, "//speech[contains(., 'Deputy Chairman of Ways and Means')]")

# Inspect raw attributes from the source
xml_attrs(matching_nodes[[1]])
xml_text(matching_nodes[[1]])