% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/add_colnames.R
\name{add_colnames}
\alias{add_colnames}
\title{Create matching column names across a list of data frames}
\usage{
add_colnames(dfs, bind = FALSE, fillwith = NA)
}
\arguments{
\item{dfs}{A list of data frames, where the length can be one.}

\item{bind}{A logical value specifying if the data frame(s)
should be returned as a single data frame. The default is
\code{FALSE}, which returns a list of data frames same as what
was provided in \code{dfs}.}

\item{fillwith}{A single value that will be used to populate all
of the missing columns.}
}
\value{
Depending on the input to \code{bind} you can either
return the same structure, i.e., a list of data frames, or
a data frame with all rows from each original data frame.
Missing values will be filled with the entry in \code{fillwith}.
}
\description{
Add missing columns to each data frame in the list allowing
for the use \code{\link[=rbind]{rbind()}} to create a single data frame.
The code is based on \code{rbind.fill} from the \code{plyr} package.
}
\examples{
x <- data.frame("a" = 1:10, "b" = 21:30)
y <- data.frame("a" = 11:15, "y" = letters[1:5])
alist <- ss3sim:::add_colnames(list(x, y), bind = FALSE)
adataframe <- ss3sim:::add_colnames(list(x, y), bind = TRUE)
# clean up
rm(x, y, alist, adataframe)
}
\author{
Kelli F. Johnson
}
