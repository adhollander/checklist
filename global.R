# Description:
#   Read RDS files into global variables.

source("prepare_data.R")

main <- function()
{
  if (!dir.exists("data/cache"))
    # Regenerate the cached RDS files.
    populate_cache()

  # Read the cached RDS files.
  issue_indicator_matrix <- readRDS(
    file.path(CACHE_DIR, "issue_indicator_matrix.rds"))
  indicator_dict <- readRDS(
    file.path(CACHE_DIR, "indicator_dict.rds"))
  issue_hierarchy <- readRDS(
    file.path(CACHE_DIR, "issue_hierarchy.rds"))

  # Make the issues vector and indicators vector.
  issues <- rownames(issue_indicator_matrix)
  indicators <- colnames(issue_indicator_matrix)

  # TODO: Old globals, to be renamed.
  issueindmat2 <<- issue_indicator_matrix
  issues2 <<- issues
  indicators2 <<- indicators

  indicatordict <<- indicator_dict

  integratedcomponent2 <<- issue_hierarchy
  integrateds <<- unique(issue_hierarchy$integrated)

  indvect2 <<- rep(1, 2017)

}

main()
