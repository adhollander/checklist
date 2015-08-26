# Description:
#   Prepare cache files from raw indicator-issue data.

library(stringr)

CACHE_DIR <- "data/cache"
FILTERS_DIR <- "data/filters"


populate_cache <- function()
  # Populate the cache from raw data.
{
  integrated_issues <- read_issues("data/indicator-integratedissue.csv",
    fields = c(
      indno = "indcatorURI",
      indicator = "indicator",
      issue = "integrated"
    ))

  component_issues <- read_issues("data/indicator-componentissue.csv",
    fields = c(
      indno = "indicatorURI",
      indicator = "indicator",
      issue = "component"
    ))

  issue_taxonomy <- read_issues("data/int_comp_issues.csv",
    fields = c(
      component = "component",
      integrated = "integrated"
    ))

  index_indicators <- read.csv("data/index-indicators.csv",
    stringsAsFactors = FALSE, header = TRUE)[[1]]

  all_issues <- rbind(component_issues, integrated_issues)

  # 1. Make the issue trees.
  ordering <- order(issue_taxonomy$integrated, issue_taxonomy$component)
  issue_taxonomy <- issue_taxonomy[ordering, ]

  filters <- append(list("All Issues" = NA), read_filters(FILTERS_DIR))

  issue_tree <-
    lapply(filters, filter_tree, create_tree(issue_taxonomy), stopened = TRUE)

  # 2. Make the issue-indicator matrix.
  issue_indicator_matrix <- table(all_issues$issue, all_issues$indicator)
  # There seems to be a bug with as.matrix() for tables.
  class(issue_indicator_matrix) <- "matrix"

  # 3. Make the issue lookup tables.
  # These map (tree issue -> issue-indicator matrix row index).
  issue_lookup <-
    lapply(issue_tree, create_lookup, rownames(issue_indicator_matrix))

  # Get all unique (indno, indicator) pairs.
  indicator_df <- unique(all_issues[c("indno", "indicator")])
  indicator_df <- indicator_df[order(indicator_df$indicator), ]

  # 4. Make the indicator data frame, for printing output.
  rownames(indicator_df) <- NULL
  colnames(indicator_df) <- c("ID", "Indicator")
  indicator_df <- indicator_df[!duplicated(indicator_df$Indicator), ]

  # 5. Get column numbers of indicators that are indexes.
  idx = match(index_indicators, all_issues$indno)
  index_indicators = na.omit(all_issues$indicator[idx])
  index_indicators = match(index_indicators, colnames(issue_indicator_matrix))
  index_indicators = unique(index_indicators)

  # Save to RDS files.
  if (!dir.exists(CACHE_DIR))
      dir.create(CACHE_DIR)

  saveRDS(issue_tree,
    file.path(CACHE_DIR, "issue_tree.rds"))
  saveRDS(issue_indicator_matrix, 
    file.path(CACHE_DIR, "issue_indicator_matrix.rds"))
  saveRDS(issue_lookup,
    file.path(CACHE_DIR, "issue_lookup.rds"))

  saveRDS(indicator_df, 
    file.path(CACHE_DIR, "indicator_df.rds"))
  saveRDS(index_indicators,
    file.path(CACHE_DIR, "index_indicators.rds"))
}


read_issues <- function(file, fields, header = TRUE, ...)
  # Read an issues file.
  #
  # This function reads a CSV format issues file. The fields argument should be
  # a named vector of columns (fields) to read. The names on the fields
  # argument are used as column names in the resulting data frame. Any column
  # named "indno" is reduced to numbers (this is purely for convenience and is
  # not a robust design).
  #
  # Args:
  #   file    file to read
  #   fields  named vector of columns to read
  #   header  whether the file has a header
  #   ...     additional arguments to read.csv()
{
  issues <- read.csv(file, stringsAsFactors = FALSE, header = header, ...)

  # Select and rename the specified fields.
  issues <- issues[fields]
  names(issues) <- names(fields)

  # Remove quotes from indicators and issues.
  char_columns <- sapply(issues, is.character)
  issues[char_columns] <- lapply(issues[char_columns], clean_string)

  # If necessary, extract indicator number from URI.
  if ("indno" %in% names(issues)) {
    issues$indno <- as.integer(str_match(issues$indno, "[0-9]+"))
  }

  return(issues)
}


read_filters <- function(dir, ...)
  # Read all filters in the specified directory.
  #
  # This function reads CSV format filters from the specified directory. Each
  # file must end in a `.csv` extension and contain a single column of
  # integrated issue names. The header (first row) is used as the filter name
  # in the user interface.
  #
  # Args:
  #   dir   filter directory
  #   ...   additional arguments to read.csv()
{
  # Only read CSV files.
  files <- list.files(dir, pattern = "[.][cC][sS][vV]$", full.names = TRUE)

  filters <- lapply(files, function(file) {
    # Read a filter.
    filter <- read.csv(
      file, check.names = FALSE, stringsAsFactors = FALSE,
      colClasses = "character", header = TRUE, ...
    )
    filter <- as.list(filter[1])

    # Clean issue names and remove duplicate issues.
    filter[[1]] <- unique(clean_string(filter[[1]]))
    
    filter
  })
  
  # Flatten the list of filters.
  filters <- unlist(filters, recursive = FALSE)

  return(filters)
}


create_tree <- function(issue_taxonomy)
  # Create a tree from an issue taxonomy.
  #
  # Args:
  #   issue_taxonomy  data frame with columns 'component' and 'integrated'
{
  # Create a branch for each integrated issue.
  tree <- split(issue_taxonomy$component, issue_taxonomy$integrated)

  # Convert each branch to a named list of 0s.
  # (this is the format the shinyTree widget uses)
  tree <- lapply(tree, function(issues) {
    branch <- numeric(length(issues))
    names(branch) <- issues

    as.list(branch)
  })

  return(tree)
}


filter_tree <- function(filter, tree, ...)
  # Filter nodes one level below the root of a tree.
  #
  # Args:
  #   filter  names of nodes to keep
  #   tree    tree with named nodes
  #   ...     additional arguments to structure(), such as attributes
{
  tree <-
    if (is.na(filter[[1]]))
      tree
    else
      tree[filter]

  # Check for invalid integrated issues in the filter.
  invalid_issues <- is.na(names(tree))
  if (any(invalid_issues)) {
    invalid_issues <- filter[invalid_issues]

    lapply(invalid_issues, function(issue) {
      msg <- sprintf("Invalid integrated issue '%s' in filter.", issue)
      warning(msg)
    })
  }

  structure(tree, ...)
}


create_lookup <- function(tree, issues)
  # Create a lookup table matching tree nodes to a vector of issues.
  #
  # Args:
  #   tree    named tree
  #   issues  issue names (e.g., row names of the issue-indicator matrix)
{
  lookup <- list()

  lookup$integrated <- match(names(tree), issues)

  components <- lapply(tree, names)
  components <- unlist(components, use.names = FALSE)
  lookup$component <- match(components, issues)

  return(lookup)
}


clean_string <- function(string)
  # Clean the name of an issue or indicator.
  #
  # Args:
  #   string  character vector
{
  # Trim leading and trailing whitespace.
  string <- str_trim(string)

  # Remove all double quotes.
  string <- gsub('"', '', string, fixed = TRUE)
  
  # Convert to title case.
  string <- gsub(
    pattern = "(^|\\s|[/(-])([[:alpha:]])",
    replacement = "\\1\\U\\2",
    string,
    perl = TRUE
  )

  # Replace " And " with " & ".
  string <- gsub(" And ", " & ", string, fixed = TRUE)

  # Replace "(Kt)" with "(kt)".
  # TODO: Find a better fix for this.
  string <- gsub("(Kt)", "(kt)", string, fixed = TRUE)

  return(string)
}


# FIXME: This function is not used and is safe to delete.
read_issue_indicator_matrix <- function()
  # Read the matrix of issues vs indicators.
  #
  # The grandmatrix.csv has indicators vs issues, 
{
  # Number of issues.
  n_issues <- 362

  colClasses <- c("character", rep.int("integer", n_issues))
  raw_matrix <- read.delim("data/grandmatrix.csv", header=TRUE
    , sep="|", colClasses=colClasses)

  n_indicators <- nrow(raw_matrix)

  # Get indicators from first column "Indicator" and issues from remaining
  # column names.
  indicators <- raw_matrix[[1]]
  issues <- colnames(raw_matrix)[-1]

  # Get the matrix.
  mat <- as.matrix(raw_matrix[-1])
  mat <- t(mat)
}
