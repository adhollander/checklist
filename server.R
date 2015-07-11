# Description:
#   Server logic for the checklist app.

library(shiny)
library(shinyTree)

library(Rsymphony)
library(stringr)


shinyServer(function(input, output, session) {
  # Render the issue trees.
  # UI tree names need to be valid JavaScript identifiers.
  filters <- names(issue_tree)
  ui_names <- sprintf("tree%i", seq_along(filters))

  output$tree_panels <- renderUI({
    mapply(create_tree_panel, filters, ui_names, SIMPLIFY = FALSE)
  })

  mapply(
    function(filter, ui_name) {
      output[[ui_name]] <- renderTree(issue_tree[filter])
    }, filters, ui_names
  )

  # Render the indicator table.
  output$indicatorResults <- renderTable({
    input$calculate_button

    # Isolate inputs, so calculations only run when the button is pressed.
    isolate({
      ui_name <- ui_names[[match(input$filter, filters)]]
      tree <- input[[ui_name]][[1]]
      lookup <- issue_lookup[[input$filter]]

      required <- match_indicators(input$required)
      excluded <- match_indicators(input$excluded)
    })

    selected_issues <- get_selected_issues(tree, lookup)
    bounds <- create_bounds(required, excluded)

    # Uncomment to have the selected issues printed in terminal:
    #print(rownames(issue_indicator_matrix)[selected_issues == 1])

    create_checklist(selected_issues, bounds)
  }, include.rownames = FALSE)
})


create_checklist <- function(selected_issues, bounds)
  # Create a table of indicators based on a vector of issues.
  # 
  # Args:
  #   selected_issues   0-1 vector of selected issues
  #   bounds            Rsymphony-format bounds list, for required/excluded
  #                     indicators
{
  nrows <- nrow(issue_indicator_matrix)

  # If no issues were selected, don't do anything.
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


get_selected_issues <- function(tree, lookup)
  # Get 0-1 vector of selected issues.
  #
  # Args:
  #   tree    the active tree, with the root removed (i.e., tree[[1]])
  #   lookup  issue lookup table corresponding to the current tree
{
  # Get issue-indicator matrix row indices for selected integrated issues.
  selected_int <- get_selected_nodes(tree)
  selected_int <- unique(lookup$integrated[selected_int])

  # Get issue-indicator matrix row indices for selected component issues.
  selected_cmp <- lapply(tree, 
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


get_selected_nodes <- function(tree, attribute = "stselected")
  # Get all selected nodes one level below the root of a tree.
  #
  # Args:
  #   tree        tree with attributes
  #   attribute   name of selection attribute
{
  vapply(tree,
    function(issue) {
      !is.null(attr(issue, attribute))
    }, TRUE
  )
}


create_bounds <- function(required, excluded)
  # Create an Rsymphony bounds list for required and excluded indicators.
  #
  # Args:
  #   required  indices vector for required indicators
  #   excluded  indices vector for excluded indicators
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


match_indicators <- function(indicators)
  # Get issue-indicator matrix column indices for indicator names.
  #
  # Args:
  #   indicators  indicator names
{
  indices <- match(indicators, colnames(issue_indicator_matrix))

  na.omit(indices)
}


create_tree_panel <- function(filter, ui_name)
  # Create a conditional panel containing a tree widget.
  #
  # This is a workaround for a bug in shinyTree that prevents tree widgets from
  # being updated correctly. Rather than updating the tree each time the filter
  # is changed, we use one tree for each filter, and update which one is
  # visible. For more details on the bug, see the shinyTree issue at:
  #   https://github.com/trestletech/shinyTree/issues/17
  #
  # Args:
  #   filter    filter for which the panel should be visible
  #   ui_name   name for the tree widget
{
  conditionalPanel(
    condition = sprintf("input.filter == '%s'", filter),
    shinyTree(ui_name, checkbox = TRUE, search = TRUE)
  )
}
