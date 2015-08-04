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
      tags$div(
        style = "overflow-y: scroll; max-height: 75vh",
        tags$label("Search Issues", class = "control-label"),
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
          options = list(selectOnTab = TRUE, maxOptions = 100)
        ),
        selectizeInput(
          "excluded",
          label = "Excluded Indicators",
          choices = colnames(issue_indicator_matrix),
          multiple = TRUE,
          options = list(selectOnTab = TRUE, maxOptions = 100)
        ),
        checkboxInput("exclude_indices", label = "Exclude Indices"),
        actionButton("calculate_button", "Calculate Checklist"),
        downloadButton("save_button", "Save")
      ),
      tableOutput("indicatorResults")
    )
  )
))
