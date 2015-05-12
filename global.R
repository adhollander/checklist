library(dplyr)
library(stringr)
library(reshape2)
library(hash)

colclassvect <- c("character", rep.int("integer", 362))
indissues <- read.csv("./data/grandmatrix.csv", header=T, sep="|", colClasses=colclassvect) 
indicators <- indissues$Indicator
issueindmat <- t(as.matrix(indissues[, 2:363], ncol=362))
indvect <- rep(1,2066) # all indicators fair game to begin with.
issues <- colnames(indissues)[2:363]

# 29 December 2014
# hokay...let's work with SPARQL exports from the actual RDF graph. 
indcomponents <- read.csv("./data/indicator-componentissue.csv", header=T)
indcomponents2 <- indcomponents %>%
#  mutate(indno = str_match(indicatorURI, "[0-9]+")) %>%
#  mutate(issue = str_replace_all(component, "\"", "")) %>%
#  mutate(indicator = str_replace_all(indicator, "\"", "")) %>%
#  mutate(indno = str_match(indicatorURI, "[0-9]+")) %>%
  mutate(indno = indicatorURI) %>%
  mutate(issue = component) %>%
  select(indno, indicator, issue)
levels(indcomponents2$issue) <- str_replace_all(levels(indcomponents2$issue), "\"", "")
levels(indcomponents2$indicator) <- str_replace_all(levels(indcomponents2$indicator), "\"", "")
levels(indcomponents2$indno) <-  str_match(levels(indcomponents2$indno), "[0-9]+")

indintegrated <- read.csv("./data/indicator-integratedissue.csv", header=T)
indintegrated2 <- indintegrated %>%
  #mutate(indno = str_match(indcatorURI, "[0-9]+")) %>%
  mutate(indno = indcatorURI) %>%
#  mutate(issue = str_replace_all(integrated, "\"", "")) %>%
#  mutate(indicator = str_replace_all(indicator, "\"", "")) %>% 
  mutate(issue = integrated) %>%
  select(indno, indicator, issue)
levels(indintegrated2$issue) <- str_replace_all(levels(indintegrated2$issue), "\"", "")
levels(indintegrated2$indicator) <- str_replace_all(levels(indintegrated2$indicator), "\"", "")
levels(indintegrated2$indno) <-  str_match(levels(indintegrated2$indno), "[0-9]+")

integratedcomponent <- read.csv("./data/int_comp_issues.csv", header=T)
integratedcomponent2 <- integratedcomponent %>%
#   mutate(component = str_replace_all(component, "\"", "")) %>%                    
#   mutate(integrated = str_replace_all(integrated, "\"", "")) %>%                                        
   select(component, integrated)
levels(integratedcomponent2$component) <- str_replace_all(levels(integratedcomponent2$component), "\"", "")
levels(integratedcomponent2$integrated) <- str_replace_all(levels(integratedcomponent2$integrated), "\"", "")


# do i need to strip out the quotes from these or not?

indissuesdf1 <- rbind(indcomponents2, indintegrated2)

issueindmat2 <- acast(indissuesdf1, issue ~ indicator)

issues2 <- rownames(issueindmat2)
indicators2 <- colnames(issueindmat2)

indicators15 <- unique(select(indissuesdf1, indno, indicator))
indicatordict <- hash(indicators15$indicator, indicators15$indno)
indvect2 <- rep(1,2017)
colclassvect2 <- c("character", rep.int("integer", 359))
integrateds <- unique(select(integratedcomponent2, integrated))$integrated

# 19 February 2015. Broke the code in a dplyr update...
# it doesn't like these str_replace_alls on the factors.
# I can fix this outside of dplyr by levels(a$b) <- str_replace_all(levels(a$b))
# ... An improvement, but I don't have integrated issue names anymore. 

# 12 April 2015
# we'll want to go from indicator id to the indicator name.
indicatorinvdict <- hash(indicators15$indno, indicators15$indicator)

vlargecost <- 1000000