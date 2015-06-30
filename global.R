# Description:
#   Read RDS files into global variables.

source("prepare_data.R")


initialize_globals <- function()
{
  if (!dir.exists("data/cache"))
    # Regenerate the cached RDS files.
    populate_cache()

  # Read the cached RDS files.
  issue_tree <- readRDS(
    file.path(CACHE_DIR, "issue_tree.rds"))
  issue_indicator_matrix <- readRDS(
    file.path(CACHE_DIR, "issue_indicator_matrix.rds"))
  indicator_df <- readRDS(
    file.path(CACHE_DIR, "indicator_df.rds"))
  indicator_dict <- readRDS(
    file.path(CACHE_DIR, "indicator_dict.rds"))

  #issue_taxonomy <- readRDS(
  #  file.path(CACHE_DIR, "issue_taxonomy.rds"))

  # Make the match vector.
  # TODO: Cache this vector.
  issues <- rownames(issue_indicator_matrix)
  integrated_lookup <<- match(names(issue_tree[[1]]), issues)

  components <- lapply(issue_tree[[1]], names)
  components <- unlist(components, use.names = FALSE)
  component_lookup <<- match(components, issues)

  # New globals.
  issue_tree <<- issue_tree
  issue_indicator_matrix <<- issue_indicator_matrix
  indicator_dict <<- indicator_dict
  indicator_df <<- indicator_df
}

initialize_globals()
