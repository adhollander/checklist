
# Changes

## 19 July 2015 (DSI Update II)

* A save button was added to the user interface. The currently selected issues 
  and computed indicators, as well as any required/excluded indicators, are 
  saved to a zip archive of CSV files.

* Required indicators now override excluded indicators.

* The selectize inputs for required and excluded indicators now list the 
  closest 100 indicators as the user is typing.

* Searching the issue tree was enabled.

* Filters were added for capital groups. Note that this is not a sorting 
  function; only one capital group can be used at a time.


## 6 July 2015 (DSI Update I)

### General Changes

* The integer program bounds bug was caused by Rsymphony. A patch was submitted 
  to the Rsymphony maintainer. Rsymphony >= 0.1-21 includes the patch.

* Code using the dplyr and reshape2 packages was replaced with plain R code.
  This is simpler and more robust (by reducing external dependencies).

* The hash package is no longer needed because indicator codes are not used. 
  Since matching indicator names with `match()` does not cause noticeable 
  performance problems, there's no need to use a hash map.

* Dead code was removed from all files. If the old code is needed, it can be 
  retrieved through `git checkout <COMMIT NUMBER>`.

* Notes on changes/progress were moved to this file.

### Data Preparation

* Data preparation was moved from `global.R` to `prepare_data.R`, in order to 
  separate concerns.

* Data preparation steps were converted to simple, reusable functions. Data 
  preparation is conducted by the `populate_cache()` function.

* Data caching was implemented. Global variables are initialized from a cache 
  directory at `data/cache`. If the cache directory is missing, the cache is 
  automatically repopulated from the raw data files. By caching global 
  variables, we avoid unnecessary computation and improves start up time.

* Four global variables are prepared by `populate_cache()`:

    + `issue_tree`: list of trees to display in the tree widget, one for each 
      filter; each is a recursive list of integrated and component issues

    + `issue_lookup`: list of issue lookup tables, one for each filter; each is 
      an integer vector of issue-indicator matrix row indices

    + `issue_indicator_matrix`: matrix of issues versus indicators; that is, 
      the left-hand side of the constraints in the integer program

    + `indicator_df`: data frame of all uniquely named indicators

* Filtering was added to control which integrated issues appear in each tree. 
  Filters should be single column CSV files, with the filter name as the 
  header. They are automatically loaded from `data/filters` (after adding new 
  filters, you may need to delete `data/cache` to force a cache update).

### Server Logic

* All functions in `server.R` were simplified and documented.

* A bug in shinyTree prevents updating the tree widget directly. As a 
  workaround, the server creates one tree widget for each filter, and only 
  displays the tree widget corresponding to the active filter.

### User Interface

* The issue checklist was replaced with a tree widget provided by the shinyTree 
  package.

* The required and excluded indicator text boxes were replaced with selectize 
  inputs. These eliminate the need to use indicator codes and ensure the input 
  is valid.

* A drop-down selection box was added to select filters for the tree.

* The submit button was replaced with an action button, so that changing the 
  active filter updates the issue tree immediately. As before, the indicator 
  list is only updated when the button is pressed.

* The sidebar was made slightly wider to accommodate the tree widget.

* Deprecated Shiny functions were updated to match the current API.

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
match('water sources', indicators2)
```
does this. so `match(indicatorinvdict[['34']], indicators2)` works. So we 
create two new ui elements, boxes to input indicator id numbers for included, 
unincluded, these get referenced in the call to `createchecklist`, we revise 
`createchecklist` so as to include these, then add the bounds parameter to the 
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
