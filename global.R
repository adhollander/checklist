# Description:
#   Read indicator-issue data from files and set up global variables.

# TODO:
# * Convert to a standalone script for making .rds files that can be loaded and
#   used without extra processing.
# * Migrate any processing steps that are currently in server.R.

library(stringr)
library(hash)

main <- function()
{
  integrated_issues <- read_issues("data/indicator-componentissue.csv",
    fields = c(
      indno = "indicatorURI",
      indicator = "indicator",
      issue = "component"
    ))

  component_issues <- read_issues("data/indicator-integratedissue.csv",
    fields = c(
      indno = "indcatorURI",
      indicator = "indicator",
      issue = "integrated"
    ))

  issue_hierarchy <- read_issues("data/int_comp_issues.csv",
    fields = c(
      component = "component",
      integrated = "integrated"
    ))

  all_issues <- rbind(component_issues, integrated_issues)

  # Make the issue-indicator matrix.
  # Formerly `acast(all_issues, issue ~ indicator)` using reshape2.
  issue_indicator_matrix <- table(all_issues$issue, all_issues$indicator)
  # There seems to be a bug with as.matrix() for tables.
  class(issue_indicator_matrix) <- "matrix"

  # Make the issues vector and indicators vector.
  issues <- rownames(issue_indicator_matrix)
  indicators <- colnames(issue_indicator_matrix)

  # Make the indicator number dictionary.
  uniq_ind <- unique(all_issues[c("indicator", "indno")])
  indicator_dict <- hash(keys = uniq_ind$indicator, values = uniq_ind$indno)

  # Map to the old globals until the server code is refactored.
  integratedcomponent2 <<- issue_hierarchy
  issueindmat2 <<- issue_indicator_matrix
  issues2 <<- issues
  indicators2 <<- indicators
  indicatordict <<- indicator_dict

  integrateds <<- unique(issue_hierarchy$integrated)
  indvect2 <<- rep(1, 2017)
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
  issues[char_columns] <- lapply(issues[char_columns], str_remove, '"')

  # If necessary, extract indicator number from URI.
  if ("indno" %in% names(issues)) {
    issues$indno <- as.integer(str_match(issues$indno, "[0-9]+"))
  }

  return(issues)
}

str_remove <- function(string, pattern)
  # Remove all pattern matches from a string.
{
  str_replace_all(string, pattern, "")
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

main()
