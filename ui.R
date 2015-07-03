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
      selectInput("filter", "Filter By",
        c("All Issues", "Impact Framework", "Vulnerability Framework")),
      div(
        style = "overflow-y: scroll; max-height: 75vh",
        shinyTree("tree", checkbox = TRUE)
      )
    ),

    # Main panel, with list of indicators.
    mainPanel(
      width = 7,
      wellPanel(
        textInput("required", "Required Indicators"),
        textInput("excluded", "Excluded Indicators"),
        actionButton("calculate", "Calculate Checklist")
      ),
      tableOutput("indicatorResults")
    )
  )
))
