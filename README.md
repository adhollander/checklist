# Sustainable Sourcing Checklist Generator

This is a R/Shiny checklist generator app for the sustainable sourcing project.

:seedling:

## Installation

1. Install the latest version of [R][].
2. Install the latest version of [RStudio Desktop][RStudio].
3. Open RStudio. In its R console, run `install.packages("devtools")`.
4. (Windows only) Install the latest version of [Rtools][], making sure "Edit 
   the system PATH" is checked.
5. Restart RStudio. In its R console, run 
   `install_github("dsidavis/checklist")`.

[R]: https://www.r-project.org/
[RStudio]: https://www.rstudio.com/
[Rtools]: https://cran.r-project.org/bin/windows/Rtools/

## Usage

After installation, in an R console, run

```{r}
library(checklist)
runChecklist()
```
