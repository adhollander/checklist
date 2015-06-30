
# Changes

---

## 12 May 2015
The bounds stuff half works, doesn't function correctly for excludeds. Suspect 
a lower-level bug. Let's try a workaround of making the costs of the excludeds
very high. This doesn't help either.... Look, Rglpk has the same interface 
function! Maybe I should try that instead.


## 3 May 2015
I accomplish something. The `envir=indicatordict@.xData` formulation gets me at 
the environment inside the hash class, and it seems to work for now. God that 
syntax is baroque though.


## 12 April 2015
How to turn this into a real application? First off, need to deal with turning 
on and off indicators. This can be done by bounds list in `Rsymphony_solve_LP`.
E.g., if indicator 2 is needed and 3 is not needed, something like
```
bounds <- list(
  lower = list(ind=c(2,3), val = c(1, 0)),
  upper = list(ind = c(2, 3), val=c(1, 0))
)
```
I hope that works. Next problem would be, how to get from indicator id numbers 
to indices of the vectors indicator id numbers to names is no problem, that's 
another hash table (unless I get similar problems with working with these)
```
match('water sources', indicators2) does this.
```
so `match(indicatorinvdict[['34']], indicators2)` works. So we create two new 
ui elements, boxes to input indicator id numbers for included, unincluded, 
these get referenced in the call to createchecklist, we revise createchecklist 
so as to include these, then add the bounds parameter to the 
`Rsymphony_solve_LP` call.

We'll want to go from indicator id to the indicator name.

## 19 February 2015
Broke the code in a dplyr update... it doesn't like these str_replace_alls on 
the factors. I can fix this outside of dplyr by
```
levels(a$b) <- str_replace_all(levels(a$b))
```
... An improvement, but I don't have integrated issue names anymore. 


## 29 December 2014
Hokay...let's work with SPARQL exports from the actual RDF graph. 
