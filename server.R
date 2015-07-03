# Description:
#   Server logic for the checklist app.

# TODO:
# * Implement tree filtering.
# * Clean up code for and cache issue lookup table.
# * Display human-readable error message for invalid required/excluded codes.

library(shiny)
library(shinyTree)

library(Rsymphony)
library(hash)
library(stringr)


parse_indicator_codes <- function(string)
  # Parse a string of indicator codes into issue-indicator matrix columns.
  #
  # Args:
  #   string  a string of indicator codes
{
  codes <- str_extract_all(string, "\\d+")[[1]]
  
  valid <- has.key(codes, indicator_dict)

  # Look up corresponding column for each indicator code.
  if (length(valid) > 0)
    values(indicator_dict, codes[valid])
}


create_bounds <- function(required, excluded)
  # Create an Rsymphony bounds list for required and excluded variables.
{
  length_required = length(required)
  length_excluded = length(excluded)

  if (length_required == 0 && length_excluded == 0)
    return(NULL)

  bounds = list()

  if (length_required > 0)
    bounds$lower <- list(ind = required, val = rep_len(1, length_required))

  if (length_excluded > 0)
    bounds$upper <- list(ind = excluded, val = rep_len(0, length_excluded))

  return(bounds)
}


create_checklist <- function(selected_issues, bounds)
  # Create a table of indicators based on a vector of issues.
  # 
  # Args:
  #   selected_issues 
  #   bounds
{
  nrows <- nrow(issue_indicator_matrix)

  if (all(selected_issues == 0))
    return(data.frame())

  ip <- Rsymphony_solve_LP(
    # Coefficients for objective (minimization).
    obj = rep_len(1, ncol(issue_indicator_matrix)),

    # Left-hand side of constraints, as a matrix.
    mat = issue_indicator_matrix,

    # Direction of constraints.
    dir = rep_len(">=", nrows),

    # Right-hand side of constraints.
    rhs = selected_issues,

    # Variable types (B for binary).
    types = rep_len("B", nrows),

    # Variable bounds.
    bounds = bounds
  )

  # Check that a solution was found.
  if (ip$status != 0)
    # TODO: Do something more robust than just printing a message.
    print("Error, solution not found!")

  # Look up the selected indicators.
  selected_indicators <- as.logical(ip$solution)
  indicator_df[selected_indicators, ]
}


get_selected_nodes <- function(tree)
  # Get all selected nodes one level below the root of a tree.
  #
  # Args:
  #   tree
{
  vapply(tree,
    function(issue) {
      !is.null(attr(issue, "stselected"))
    }, TRUE)
}


get_selected_issues <- function(tree, lookup)
  # Get 0-1 vector of selected issues.
  #
  # Args:
  #   tree
  #   lookup
{
  # Get issue-indicator matrix rows for selected integrated issues.
  selected_int <- get_selected_nodes(tree[[1]])
  selected_int <- unique(lookup$integrated[selected_int])

  # Get issue-indicator matrix rows for selected component issues.
  selected_cmp <- lapply(tree[[1]], 
    function(int_issue) {
      if (class(int_issue) == "list")
        get_selected_nodes(int_issue)
    }
  )
  selected_cmp <- unlist(selected_cmp)
  selected_cmp <- unique(lookup$component[selected_cmp])

  # Assign 1 to selected issues, and 0 otherwise.
  selected_issues <- numeric(nrow(issue_indicator_matrix))
  selected_issues[selected_int] = 1
  selected_issues[selected_cmp] = 1

  return(selected_issues)
}


shinyServer(function(input, output) {
  # Display the indicator table.
  output$indicatorResults <- renderTable({
    input$calculate

    selected_issues <- isolate(get_selected_issues(input$tree, issue_lookup))

    bounds <- isolate({
      required <- parse_indicator_codes(input$required)
      excluded <- parse_indicator_codes(input$excluded)
      create_bounds(required, excluded)
    })

    create_checklist(selected_issues, bounds)
  }, include.rownames = FALSE)

  # Display the issue tree.
  output$tree <- renderTree({
    issue_tree[input$filter]
  })
})
