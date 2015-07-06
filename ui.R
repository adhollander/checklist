# Description:
#   User interface for the checklist app.
#
# Usage:
#   runApp("checklist/")

library(shiny)
library(shinyTree)

shinyUI(fluidPage(
  
  # Application title.
  titlePanel("Checklist Generator Prototype"),
  
  sidebarLayout(
    # Sidebar, with tree of issues.
    sidebarPanel(
      width = 5,
      selectInput("filter", "Filter By", names(issue_tree)),
      div(
        style = "overflow-y: scroll; max-height: 75vh",
        uiOutput("tree_panels")
      )
    ),

    # Main panel, with list of indicators.
    mainPanel(
      width = 7,
      wellPanel(
        selectizeInput(
          "required",
          label = "Required Indicators",
          choices = colnames(issue_indicator_matrix),
          multiple = TRUE,
          options = list(selectOnTab = TRUE, maxOptions = 5)
        ),
        selectizeInput(
          "excluded",
          label = "Excluded Indicators",
          choices = colnames(issue_indicator_matrix),
          multiple = TRUE,
          options = list(selectOnTab = TRUE, maxOptions = 5)
        ),
        actionButton("calculate_button", "Calculate Checklist")
      ),
      tableOutput("indicatorResults")
    )
  )
))
