#' Create template argument input files
#'
#' Creates template input files based on the argument lists for
#' specified functions. Look in your working directory for the
#' template files. Change the case ID number (defaults to \code{0})
#' and the species identifier to a three letter identifier. For the
#' FISH600 project use one of \code{cod}, \code{sar}, or \code{fla}
#' for cod, sardine, or flatfish. An example filename would be
#' \code{M1-sar.txt} or \code{lcomp2-fla.txt}.
#'
#' @param functions A named vector. The names correspond to the
#' filenames that will get written. The values correspond to the
#' functions to grab the arguments from.
#' @param ext The file extension to create the configuration files
#' with. Defaults to \code{".txt"}.
#' @param delim The delimiter. Defaults to \code{"; "}.
#' @param ignore A vector of character object of arguments to ignore in the
#' arguments. Found via \code{grep} so can be part of an argument
#' name.
#' @param ... Anything else to pass to \code{write.table}.
#' @author Sean Anderson
#' @examples \dontrun{
#' create_argfiles()
#' # Some example input lines:
#' # 
#' # year1; 1990
#' # years; 1990:2000
#' # years; c(1980, 1990, 1995)
#' # survey_type; fishery
#' }
#' @export
#' @details
#' The first column in the text files denotes the argument to be
#' passed to a function. The second argument denotes the value to be
#' passed. You can use any simple R syntax. For example: \code{c(1, 2,
#' 4)}, or \code{seq(1, 100)} or \code{1:100} or \code{matrix()}.
#' Character objects don't need to be quoted. However, be careful not
#' to use your delimiter (set up as a semicolon) anywhere else in the
#' file besides to denote columns. 


create_argfiles <- function(functions = c("lcomp0-spp" =
    "change_lcomp", "agecomp0-spp" = "change_agecomp", "index0-spp" =
    "change_index", "M0-spp" = "change_m", "F0-spp" = "change_f",
<<<<<<< HEAD
    "R0-spp" = "change_retro", "E0-spp" = "change_e"), ext = ".txt", delim = "; ", ignore =
=======
    "R0-spp" = "change_retro", "S0-spp" = "change_sel", "G0-spp" =
    "change_growth"), ext = ".txt", delim = "; ", ignore =
>>>>>>> develop
  c("file", "dir", "make_plot"), ...) {
  if(!is.character(functions)) 
    stop("Functions must be a vector of character.")
  for(i in 1:length(functions)) {
    x <- formals(functions[i])
    args_ignore <- as.numeric(unlist(sapply(ignore,
          function(z) grep(z, names(x)))))
    print(paste("Ignoring", names(x)[args_ignore], "in", functions[i]))
    x <- x[-args_ignore]
    d <- data.frame(args = names(x), vals = as.character(x))
    write.table(d, file = paste0(names(functions)[i], ext), sep = delim,
      row.names = FALSE, col.names = FALSE, quote = FALSE, ...)
  }
  print(paste("Created the template file", paste0(names(functions), ext)))
}
