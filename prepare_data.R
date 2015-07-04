# Description:
#   Prepare RDS files from raw indicator-issue data.

library(stringr)
library(hash)

CACHE_DIR <- "data/cache"

IMPACT_FRAMEWORK <- c(
  "Agricultural Sector",
  "Air & Climate",
  "Biodiversity",
  "Common Pool Resources",
  "Deforestation",
  "Ecosystem Services",
  "Food Production",
  "Governance",
  "Human Rights",
  "Income",
  "Labor",
  "Land & Soil",
  "Markets",
  "Nutritional Status",
  "Participation",
  "Poverty",
  "Property Rights",
  "Public Health",
  "Safety",
  "Sociocultural Systems",
  "Technology",
  "Wastes & Pollution",
  "Water",
  "Women & Wages"
)
# TODO: Uniquify

VULNERABILITY_FRAMEWORK <- c(
"Agricultural Sector",
"Air & Climate",
"Biodiversity",
"Deforestation",
"Disasters",
"Diseases",
"Ecosystem Services",
"Educational Resources",
"Energy",
"Finance",
"Food Production",
"Geographical Distribution",
"Governance",
"Human Rights",
"Income",
"Inputs",
"Institutions",
"Labor",
"Land & Soil",
"Literacy",
"Markets",
"Nutritional Status",
"Participation",
"Physical Infrastructure",
"Population Growth",
"Population Structure",
"Poverty",
"Productivity",
"Property Rights",
"Public Health",
"Social Structure",
"Sociocultural Systems",
"Technology",
"Trade Policies",
"Wastes & Pollution",
"Water"
)


populate_cache <- function()
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

  all_issues <- rbind(component_issues, integrated_issues)

  # Make the issue tree.
  issue_taxonomy <- issue_taxonomy[
    order(issue_taxonomy$integrated, issue_taxonomy$component), ]
  filters <- list(
    "All Issues" = NA,
    "Impact Framework" = IMPACT_FRAMEWORK,
    "Vulnerability Framework" = VULNERABILITY_FRAMEWORK
  )
  issue_tree <- lapply(
    filters, filter_tree,
    create_tree(issue_taxonomy),
    stopened = TRUE
  )

  # Make the issue-indicator matrix.
  # Formerly `acast(all_issues, issue ~ indicator)` using reshape2.
  issue_indicator_matrix <- table(all_issues$issue, all_issues$indicator)
  # There seems to be a bug with as.matrix() for tables.
  class(issue_indicator_matrix) <- "matrix"

  # Make the issue lookup tables.
  issue_lookup <- lapply(issue_tree, create_lookup,
    rownames(issue_indicator_matrix))

  # FIXME:
  # Get all unique (indno, indicator) pairs.
  indicator_df <- unique(all_issues[c("indno", "indicator")])
  indicator_df <- indicator_df[order(indicator_df$indicator), ]

  # Make a dictionary mapping indno -> issue-indicator matrix column.
  matched <- match(indicator_df$indicator, colnames(issue_indicator_matrix))
  indicator_dict <- hash(keys = indicator_df$indno, values = matched)

  # Make a data frame of indicator info, for printing.
  rownames(indicator_df) <- NULL
  colnames(indicator_df) <- c("ID", "Indicator")
  indicator_df <- indicator_df[!duplicated(indicator_df$Indicator), ]

  # Save the RDS files.
  if (!dir.exists(CACHE_DIR))
      dir.create(CACHE_DIR)

  saveRDS(issue_tree,
    file.path(CACHE_DIR, "issue_tree.rds"))
  saveRDS(issue_indicator_matrix, 
    file.path(CACHE_DIR, "issue_indicator_matrix.rds"))
  saveRDS(issue_lookup,
    file.path(CACHE_DIR, "issue_lookup.rds"))

  saveRDS(indicator_dict,
    file.path(CACHE_DIR, "indicator_dict.rds"))
  saveRDS(indicator_df, 
    file.path(CACHE_DIR, "indicator_df.rds"))
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
  #   header
  #   ...     additional arguments to read.csv
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


filter_tree <- function(filter, tree, ...)
{
  tree <-
    if (is.na(filter[[1]]))
      tree
    else
      tree[filter]

  structure(tree, ...)
}

create_tree <- function(issue_taxonomy)
  # Create a tree from an issue taxonomy.
  #
  # Args:
  #   issue_taxonomy
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


create_lookup <- function(tree, issues)
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


# FIXME: Deprecated
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
