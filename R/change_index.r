#' Change index values
#'
#' This function is used to create an index of abundance sampled from the
#' true biomass. It takes the biomass from the Report.sso file using the
#' r4ss function and then splits it.
#' 
#' @param operating.model.path
#' @param assessment.model.path
#' @param dat.filename
#' @param start.year
#' @param end.year
#' @param frequency
#' @param sd.obs
#' @param make.plot
#' @export

write_index <- function(operating.model.path, assessment.model.path,
  dat.filename, start.year, end.year, frequency=1,
  sd.obs = .1, make.plot=FALSE){
  
  require(r4ss)
  ## Calculate which years to have the index values
  years.survey <- seq(from=start.year, to=end.year, by=frequency)
  
  ## Grab the biomass from the report file generated by the operating model; drop
  ## the first two rows since they aren't what we want
  ts <- SS_output(dir=operating.model.path, repfile="Report.sso",
    covar=F, verbose=FALSE, printstats=FALSE)$timeseries[-c(1,2),]
  bio_all <- ts$Bio_all
  yr <- ts$Yr
  bio <- bio_all[yr %in% years.survey] # biomass for years w/ survey
  if(length(bio)==0) stop("Error: no matching years, index has length 0")
  index <- bio*exp(rnorm(n=length(bio), mean=0, sd=sd.obs)-sd.obs^2/2)
  index.text <- paste(years.survey, 1, 2, index, sd.obs)
  ## Just for testing purposes. Create crude plots?
  if(make.plot){
    plot(yr, bio_all, ylim=c(0, max(index)*1.1), type="l")
    points(years.survey, index, pch=16)
  }
  ## Open the .dat file for the assessment model and find the right lines to
  ## overwrite
  dat.current <- readLines(paste0(assessment.model.path,"/", dat.filename))
  ## Write to file how many lines to read
  ind.N <- grep("#_N_cpue_and_surveyabundance_observations", x=dat.current)
  dat.current[ind.N] <- paste(length(years.survey),
    " #_N_cpue_and_surveyabundance_observations -- created by write_index.R script")
  ind.start <- grep("#_year seas index obs se_log", x=dat.current)
  ind.end <- grep("#_N_discard_fleets", x=dat.current)
  dat.new <- c(dat.current[1:ind.start], index.text,
    dat.current[ind.end:length(dat.current)])
  ## Write it back to file, overwriting the original
  writeLines(text=dat.new, con=paste0(assessment.model.path,"/", dat.filename))
}

# write_index(getwd(), "../flatfish assessment model", "assessment_flatfish.dat",
#           1930, 1981, 1, make.plot=T)
