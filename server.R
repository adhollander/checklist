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
  # Get all selected nodes one level below the root.
  #
  # Args:
  #   tree
{
  vapply(tree,
    function(issue) {
      !is.null(attr(issue, "stselected"))
    }, TRUE)
}


get_selected_issues <- function(tree)
  # Get vector of selected issues.
  #
  # Args:
  #   tree
{
  # Integrated issues and component issues go in separate vectors.
  int_selected <- get_selected_nodes(tree[[1]])
  int_selected <- unique(integrated_lookup[int_selected])

  cmp_selected <- lapply(tree[[1]], 
    function(int_issue) {
      if (class(int_issue) == "list")
        get_selected_nodes(int_issue)
    }
  )
  cmp_selected <- unlist(cmp_selected)
  cmp_selected <- unique(component_lookup[cmp_selected])

  # Lookup values and return the indicator.
  issue_ind <- numeric(nrow(issue_indicator_matrix))
  issue_ind[int_selected] = 1
  issue_ind[cmp_selected] = 1

  return(issue_ind)
}


shinyServer(function(input, output) {
  # Cache selected issues.
  selected_issues <- reactive({
    get_selected_issues(input$tree)
  })

  # Cache bounds for required and excluded indicators.
  bounds <- reactive({
    required <- parse_indicator_codes(input$required)
    excluded <- parse_indicator_codes(input$excluded)
    create_bounds(required, excluded)
  })

  # Display the indicator table.
  output$indicatorResults <- renderTable({
    create_checklist(selected_issues(), bounds())
  })

  # Display the issue tree.
  output$tree <- renderTree({
      issue_tree
  })
})
