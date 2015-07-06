# Description:
#   Initialize global variables.

source("prepare_data.R")


initialize_globals <- function()
  # Initialize global variables from the cache.
{
  if (!dir.exists("data/cache"))
    # Regenerate the cached RDS files.
    populate_cache()

  # Read the cached RDS files.
  issue_tree <- readRDS(
    file.path(CACHE_DIR, "issue_tree.rds"))
  issue_indicator_matrix <- readRDS(
    file.path(CACHE_DIR, "issue_indicator_matrix.rds"))
  issue_lookup <- readRDS(
    file.path(CACHE_DIR, "issue_lookup.rds"))

  indicator_df <- readRDS(
    file.path(CACHE_DIR, "indicator_df.rds"))

  # Global variables.
  issue_tree <<- issue_tree
  issue_indicator_matrix <<- issue_indicator_matrix
  issue_lookup <<- issue_lookup

  indicator_df <<- indicator_df
}

initialize_globals()
