# Description:
#   Initialize global variables.

source("prepare_data.R")


initialize_globals <- function()
  # Initialize global variables from the cache.
{
  if (!dir.exists("data/cache"))
    # Regenerate the cached RDS files.
    populate_cache()

  # Read the cached RDS files into global variables.
  issue_tree <<-
    readRDS(file.path(CACHE_DIR, "issue_tree.rds"))
  issue_indicator_matrix <<-
    readRDS(file.path(CACHE_DIR, "issue_indicator_matrix.rds"))
  issue_lookup <<-
    readRDS(file.path(CACHE_DIR, "issue_lookup.rds"))

  indicator_df <<- 
    readRDS(file.path(CACHE_DIR, "indicator_df.rds"))
  indicator_indices <<-
    readRDS(file.path(CACHE_DIR, "index_indicators.rds"))
}

initialize_globals()
