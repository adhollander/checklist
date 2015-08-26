
#' Checklist Launcher
#'
#' Run the checklist app.
#'
#' @export
runChecklist = function()
{
  app_dir <- system.file("checklist", package = "checklist")
  if (app_dir == "") {
    stop("Couldn't find the checklist app. Try re-installing the package.",
      call. = FALSE)
  }

  shiny::runApp(app_dir, display.mode = "normal")
}
