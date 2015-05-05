
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
# 
# http://www.rstudio.com/shiny/
#

library(shiny)

shinyUI(pageWithSidebar(
  
  # Application title
  headerPanel("Prototype of Checklist Generator Prototype"),
  
  # Sidebar with a slider input for number of bins
  sidebarPanel(
    checkboxGroupInput("issuevect", label=NULL, choices=(integrateds = levels(integrateds)), selected=integrateds)),
                                          # formerly issues2 ^
  # Show a text list of indicators
  mainPanel(
    tableOutput("indicatorResults")
  )
))

# run with runApp("~/ASI/checklist/shiny")