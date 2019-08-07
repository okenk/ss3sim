#' Alter fishing mortality (\emph{F}) using the SS control file
#'
#' Alter fishing mortality (\emph{F}) for a Stock Synthesis simulation 
#' via changes to the control file. The argument \code{years} is the only
#' argument that must be a vector, where other vectors, e.g., \code{fisheries},
#' will be repeated if a single value is provided. 
#' 
#' Using the control file depends on 
#' (1) the starter file is set up to read parameters from the control file 
#' rather than the par file and
#' (2) the data file having a dummy catch entry for every year, fishery
#' combination that will be specified in the control file. 
#' \emph{F} values currently in the control file will be removed and 
#' the newly specified values will replace them.
#' Users do not need to specify values for years in which there
#' will be zero fishing because SS will be parameterized to assume 
#' no fishing in missing years.
#' 
#' The control file is currently read in using \code{readLines} but will
#' eventually shift to using code specific to Stock Synthesis to alter
#' a structured list.
#' If used with \code{\link{run_ss3sim}}, the case file should be named
#' \code{F}. A suggested (default) case letter is \code{F}.
#'
#' @author Kelli Faye Johnson
#'
#' @param years *Vector of integers that will map to each \code{fvals} 
#' specifying which year the fishing level pertains to.
#' @param fisheries *Vector of integers that will map to each \code{fvals}
#' specifying which fleet the fishing level pertains to.
#' A single value will be repeated for every value in \code{years} or
#' \code{length(years) == length(fisheries)} must be true.
#' @param fvals *Vector of \emph{F} values to be entered into the 
#' SS control file. A single value will be repeated for every value in \code{years} or
#' \code{length(years) == length(fvals)} must be true.
#' @param seasons Vector of seasons to be entered into the
#' SS control file. A single value will be repeated for every value in \code{years} or
#' \code{length(years) == length(ses)} must be true. 
#' The default is 1, which will be applied to all fisheries in all years.
#' @param ses Vector of fishing level standard errors (ses) to be entered into the
#' SS control file. A single value will be repeated for every value in \code{years} or
#' \code{length(years) == length(ses)} must be true. 
#' The default is 0.005, which will be applied to all fisheries in all years.
#' @template ctl_file_in
#' @template ctl_file_out
#' @return Modified SS control file.
#' @family change functions
#' @template casefile-footnote
#' @export
#' @examples
#' d <- system.file(file.path("extdata", "models"), package = "ss3sim")
#' change_f_ctl(years = 1:50, fisheries = 1, fvals = 0.2,
#'   ctl_file_in = file.path(d, "cod-om", "codOM.ctl"),
#'   ctl_file_out = file.path(tempdir(), "control_fishing.ss"))

change_f <- function(years, fisheries, fvals, seasons = 1, ses = 0.005,
  ctl_file_in, ctl_file_out = "control_fishing.ss") {

  n.years <- length(years)

   if (length(fvals) != 1 & length(fvals) != n.years) {
    stop("The number of years to alter, ", n.years,
      ", does NOT equal length of supplied F values, ", length(fvals))
   }
   if (length(fisheries) != 1 & length(fisheries) != n.years) {
    stop("The number of years to alter, ", n.years,
      ", does NOT equal length of supplied fleet values, ", length(fisheries),
      ". Please change the number of fleet values so there is either 1 value ",
      "or ", n.years, " values.")
  }
  newdata <- data.frame(
    "Fleet" = fisheries,
    "Yr" = years,
    "Seas" = seasons,
    "F_value" = fvals,
    "se" = ses,
    "phase" = 1)

  ctl <- readLines(ctl_file_in)
  locations <- grep("F_Method", ctl, ignore.case = TRUE)
  if (length(locations) < 2) stop("F_Method wasn't found in the control file")
  locations <- locations[c(1, length(locations))]
  location_terminal <- grep("Q_setup", ctl, ignore.case = FALSE)
  ctl[locations[1]] <- gsub("^[1-4]\\s*", "2 ", trimws(ctl[locations[1]]))
  location_middle <- (locations[1] + 1):(locations[2] - 1)
  ctl[location_middle] <- c(
    paste(ifelse(max(fvals) < 4, 4, max(fvals) * 2), 
      " # max F or harvest rate, depends on F_Method"),
    rep("#", length(location_middle) - 2),
    paste(0, 1, length(years), "# overall start F value; overall phase; N detailed inputs to read"))
  ctl <- ctl[-((locations[2] + 1):(location_terminal-1))]
  ctl <- append(ctl, 
    values = apply(newdata, 1, paste, collapse = " "),
    after = locations[2])

  # Write new control file
  if (!is.null(ctl_file_out)) {
    writeLines(ctl, con = ctl_file_out)
    close(file(ctl_file_out))
  }
  invisible(ctl)
}
