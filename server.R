
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
# 
# http://www.rstudio.com/shiny/
#

library(shiny)
#library(lpSolve)
library(Rsymphony)
library(dplyr)
library(tidyr)
library(stringr)

# createchecklist <- function(indvect, issuevect, issueindmat) {
#   dirvect <- rep(">=", length(issuevect))
#   iptest1 <- lp("min", indvect, issueindmat, dirvect, issuevect, all.bin=TRUE, num.bin.solns=1)
#   indicatordf <- data.frame(indicators[iptest1$solution==1])
#   colnames(indicatordf)[1] <- "Indicator"
#   return(indicatordf)
# }

# the version for the grandmatrix.csv...
# createchecklist <- function(indvect, issuevect, issueindmat) {
#   dirvect <- rep(">=", length(issuevect))
#   #iptest1 <- lp("min", indvect, issueindmat, dirvect, issuevect, all.bin=TRUE, num.bin.solns=1)
#   iptest1 <- Rsymphony_solve_LP(indvect, issueindmat, dirvect, issuevect, types=(rep("B", length(indvect))))
#   indicatordf <- data.frame(indicators[iptest1$solution==1])
#   colnames(indicatordf)[1] <- "ind0"
#   indicatordf2 <- indicatordf %>%
#     separate(ind0, into=c("ID", "Indicator"), sep="@") %>%
#     select(ID, Indicator)
#   return(indicatordf2)
# }
# 
# 
# makeissuevect <- function(issuelist) {
#   issuematches <- match(issuelist, issues)
#   issvect <- rep(0, length(issues))
#   issvect[issuematches] = 1
#   issvect  
# }
# 
# 
# shinyServer(function(input, output) {
#   output$indicatorResults <- renderTable(createchecklist(indvect, makeissuevect(input$issuevect), issueindmat)) 
#   
# })


# From vector of indicator numbers, get indices of vectors
getindicatorvectnos <- function(indidstr) {
  vectidstr <- str_extract_all(indidstr, "\\d+")[[1]]
  indnames <- as.character(values(indicatorinvdict[vectidstr[has.key(vectidstr, indicatorinvdict)]]))
  vectindices <- match(indnames, indicators2)
  vectindices
}

# Create list for Rsymphony call
makeboundslist <- function(requireds, excludeds){
  requiredids <- NULL
  excludedids <- NULL
  if(nchar(requireds) > 0) {
    requiredids <- getindicatorvectnos(requireds)
  }
  if(nchar(excludeds) > 0) {
    excludedids <- getindicatorvectnos(excludeds)
  }
  indlist <- c(requiredids, excludedids)
  vallist <- c(rep(1, length(requiredids)), rep(0, length(excludedids)))
  if(length(indlist) == 0) {bounds <- NULL}
  else {
    bounds <- list(lower = list(ind=indlist, val=vallist),
                   upper = list(ind=indlist, val=vallist))
  }
  bounds
}


# 30 December 2014
# now based on SPARQL output...
createchecklist <- function(indvect, issuevect, issueindmat, requireds, excludeds) {
  dirvect <- rep(">=", length(issuevect))
  #iptest1 <- lp("min", indvect, issueindmat, dirvect, issuevect, all.bin=TRUE, num.bin.solns=1)
  # okay, here goes with the bounds stuff
  bounds <- makeboundslist(requireds, excludeds)
  #
  iptest1 <- Rsymphony_solve_LP(indvect, issueindmat, dirvect, issuevect, types=(rep("B", length(indvect))), bounds=bounds)
  indicatordf <- data.frame(indicators2[iptest1$solution==1])
  colnames(indicatordf)[1] <- "Indicator"
  indicatordf2 <- indicatordf %>%
    #mutate(ID = indicatordict[[as.character(Indicator)]])) %>%  # not working, don't know why. wish the R folks thought about hashes 15 yrs ago
    #mutate(ID = -9999) %>%
    #mutate(ID = str_split(Indicator, "@")[[1]][1]) %>%
    #mutate(ID = Indicator) %>%
    #mutate(ID = indicatordict[[Indicator]]) %>% 
    mutate(ID = unlist(mget(unlist(as.character(Indicator)), envir=indicatordict@.xData))) %>%
    select(ID, Indicator)
  return(indicatordf2)
}

# now amended to loop through issuelist if only looking at integrateds, and add in component issues
makeissuevect <- function(issuelist, integratedonly=F) {
  if (integratedonly) {
    componentvect <- vector()
    for(i in 1:nrow(integratedcomponent2)) {
      currentintegrated <- integratedcomponent2[i,2]
      if(currentintegrated %in% issuelist) {
        componentvect <- union(componentvect, integratedcomponent2[i,1])}
    }
    #print(componentvect)
    issuematches <- union(match(issuelist, issues2), match(componentvect, issues2))}
  else {issuematches <- match(issuelist, issues2)}
  print(issuematches)
  issvect <- rep(0, length(issues2))
  issvect[issuematches] = 1
  issvect  
}


shinyServer(function(input, output) {
  output$indicatorResults <- renderTable(
    createchecklist(indvect2, makeissuevect(input$issuevect, integratedonly=T), issueindmat2, input$requireds, input$excludeds))
})

# 12 April 2015. How to turn this into a real application? First off, need to deal with turning on and off indicators.
# this can be done by bounds list in Rsymphony_solve_LP. E.g., if indicator 2 is needed and 3 is not needed,
# something like bounds <- list(lower = list(ind=c(2,3), val = c(1, 0))), upper = list(ind = c(2, 3), val=c(1, 0))
# I hope that works. Next problem would be, how to get from indicator id numbers to indices of the vectors
# indicator id numbers to names is no problem, that's another hash table (unless I get similar problems with working with these)
# match('water sources', indicators2) does this.
# so match(indicatorinvdict[['34']], indicators2) works.
# So we create two new ui elements, boxes to input indicator id numbers for included, unincluded, 
# these get referenced in the call to createchecklist, we revise createchecklist so as to include these, then add
# the bounds parameter to the Rsymphony_solve_LP call.

# 3 May 2015. I accomplish something. The  envir=indicatordict@.xData formulation gets me at the environment inside
# the hash class, and it seems to work for now. God that syntax is baroque though.