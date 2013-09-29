#' Methods to include time-varying parameters in the OM
#'
#' @description Takes an SS3 \code{.ctl}, \code{.par}, and \code{.dat}
#' file and implements the use of environmental variables to enable
#' time-varying parameters. Specifically set up to work with an
#' operating model \code{.ctl} file.
#'
#' @param change_tv_list A list of named vectors. Names correspond to
#' parameters in the operating model that are currently constant
#' across time and will be changed to vary across time according to
#' the vector of deviations. The vector of deviations will function
#' as additive deviations from the value specified in the \code{.par}
#' file for the given parameter. Vectors of deviations, also referred
#' to as environmental data, must be of \code{length = length of *.dat
#' endyr-startyr+1}. Specify years without deviations as vectors of
#' zero. Parameter names must be unique and be specified
#' as the full parameter name in the \code{.ctl} file.
#' Names for stock recruit parameters must contain "devs", "R0", or 
#' "steep", and only one stock recruit parameter can be time-varying
#' per model.
#' The feature will include an *additive* functional linkage
#' between environmental data and the parameter where the
#' link parameter is fixed at a value of one:
#' \code{par\' (y) = par + link * env(y)}
#' For catchability (q) the *additive* functional linkage
#' is implemented on the log scale:
#' \code{ln_{q}(y) = ln_{q Base} + link * env(y)}
#' @param ctl_file_in Input SS3 control file
#' @param ctl_file_out Output SS3 control file
#' @param dat_file_in Input SS3 data file
#' @param dat_file_out Output SS3 data file
#' @param par_file_in Input SS3 paramater file
#' @param par_file_out Output SS3 parameter file
#' @param starter_file_in Input SS3 starter file
#' @param starter_file_out Output SS3 starter file
#' @param report_file Input SS3 report file
#' @author Kotaro Ono, Carey McGilliard, and Kelli Faye Johnson
#' @export
#'
#' @details Although there are three ways to implement time-varying
#' parameters within SS3, \code{ss3sim} only uses the environmental
#' variable option. The \code{ctl_file_in} argument needs to be a
#' \code{.ss_new} file because the documentation in \code{.ss_new}
#' files are automated and standardized. This function takes advantage
#' of the standard documentation the SS3 control file to determine
#' which lines to manipulate and where to add code in the
#' \code{.ctl}, \code{.par}, and \code{.dat} files, code that is necessary
#' to implement time-varying parameters.
#' Within SS, time-varying parameters work on an annual time-step.
#' Thus for models with multiple seasons, the time-varying parameters
#' will remain constant for the entire year.
#' ss3sim uses annual recruitment deviations and may not work
#' with a model that ties recruitment deviations to environmental
#' covariates. If you need to compare the environment to annual
#' recruitment deviations, the preferred option is to transform the
#' environmental variable into an age 0 pre-recruit survey. See
#' page 55 of the SS3 version 3.24f manual for more information.
#'
#' @examples
#' \dontrun{
#' d <- system.file("extdata", package = "ss3sim")
#' ctl_file_in <- paste0(d, "/Simple/control.ss_new")
#' dat_file_in <- paste0(d, "/Simple/simple.dat")
#' starter_file_in <- paste0(d, "/Simple/starter.ss")
#' par_file_in <- paste0(d, "/Simple/ss3.par")
#' report_file <- paste0(d, "/Simple/Report.sso")
#' wd <- getwd()
#' setwd(paste0(d, "/Simple"))
#' change_tv(change_tv_list = list("NatM_p_1_Fem_GP_1" = c(rep(0, 20), rep(.1, 11)),
#'                                 "SizeSel_1P_1_FISHERY1" = rnorm(31, 0, 0.05),"recdevs"=rep(1,31)),
#'   ctl_file_in = ctl_file_in, ctl_file_out = "example.ctl",
#'   dat_file_in = dat_file_in, dat_file_out = "example.dat",
#'   starter_file_in = starter_file_in, starter_file_out = "starter.ss",
#'   par_file_in = par_file_in, report_file = report_file
#'   )
# # clean up:
# file.remove("example.ctl")
# file.remove("example.dat")
#' setwd(wd)}

change_tv <- function(change_tv_list,
  ctl_file_in = "control.ss_new", ctl_file_out = "om.ctl",
  dat_file_in = "ss3.dat", dat_file_out = "ss3.dat",
  par_file_in = "ss3.par", par_file_out="ss3.par",
  starter_file_in = "starter.ss", starter_file_out = "starter.ss",
  report_file = "Report.sso") {

  ss3.ctl    <- readLines(con = ctl_file_in)
  ss3.dat    <- readLines(con = dat_file_in)
  ss3.starter<- readLines(con = starter_file_in)
  ss3.report <- readLines(con = report_file)

  year.beg <- grep("#_styr",  ss3.dat, value = TRUE )
  year.end <- grep("#_endyr", ss3.dat, value = TRUE )
  year.beg <- as.numeric(sub(" ", "", strsplit(year.beg, "#")[[1]][1]))
  year.end <- as.numeric(sub(" ", "", strsplit(year.end, "#")[[1]][1]))

# For all variables the following coding is used
   # mg = Natural mortality and growth parameters
   # sr = Stock recruit parameters
   # qs = Catchability paramaters
   # sx = Selectivity parameters

  baseom.tv <- grep("_ENV", ss3.report, value = TRUE)
  baseom.tv <- sapply(baseom.tv, function(x) {
                        temp <- strsplit(x, "_ENV")[[1]][1]
                        strsplit(temp, " ")[[1]][2]
                      })
  if(any(baseom.tv %in% names(change_tv_list) == "TRUE")) {
    stop("One or more of the parameters listed in change_tv is already time-varying
          in the base operating model. ss3sim cannot change time-varying properties
          of parameters that are already specified as time-varying.")
  }

  dat.varnum.text <- grep("#_N_environ_variables", ss3.dat,
                          fixed = TRUE, value = TRUE)
  dat.varnum <- as.numeric(gsub('([0-9]*).*','\\1', dat.varnum.text))
  dat.varnum.counter <- dat.varnum
  dat.tbl.ch <- c(grep("#_N_environ_obs",              ss3.dat, fixed = TRUE),
                  grep("# N sizefreq methods to read", ss3.dat, fixed = TRUE))
  ss3.dat.top <- ss3.dat[1:dat.tbl.ch[1]]
  if(dat.tbl.ch[2] - dat.tbl.ch[1] == 1) {
    ss3.dat.tbl <- data.frame(array(dim=c(0,3),
                                    dimnames = list(NULL,
                                                    c("year", "variable", "value"))))
  } else {
      ss3.dat.tbl <- as.data.frame(ss3.dat[(dat.tbl.ch[1] + 1) :
                                           (dat.tbl.ch[2] - 1)],
                                   stringsAsFactors = FALSE)
    }
  ss3.dat.bottom <- ss3.dat[dat.tbl.ch[2]:length(ss3.dat)]

  mg.ch <- grep("#custom_MG-env_setup (0/1)",   ss3.ctl, fixed = TRUE)
  sx.ch <- grep("#_custom_sel-env_setup (0/1)", ss3.ctl, fixed = TRUE)

  fleet.names <- ss3.dat[grep("#_N_areas", ss3.dat)[1] + 1]
  fleet.names <- strsplit(fleet.names, "%")[[1]]

  divider.a <- grep("#_Spawner-Recruitment", ss3.ctl, fixed = TRUE)[1]
  divider.b <- grep("#_Q_setup", ss3.ctl, fixed = TRUE)[1]
  divider.c <- grep("selex_types", ss3.ctl, fixed = TRUE)[1]
  lab <- sapply(names(change_tv_list), function(x) {
                               val <- grep(pattern = x, x = ss3.ctl, fixed = TRUE)[1]
                               if(is.na(val)) {
                                 stop(paste("Could not locate the parameter", 
                                            x, "in the operating model .ctl file.", 
                                            "Check that the parameter is spelled",
                                            "correctly and in the correct case.",
                                            "Have you standardized your .ctl file",
                                            "by running it through SS and used the control.ss_new file?"))}
                               if(val < divider.a) temp <- "mg"
                               if(val > divider.a & val < divider.b) temp <- "sr"
                               if(val > divider.b & val < divider.c) temp <- "qs"
                               if(val > divider.c) temp <- "sx"
                               if(x %in% fleet.names) temp <- "qs"
                               temp
                             })
  tab <- as.data.frame.table(table(lab))
  if(subset(tab, lab == "mg", select = "Freq") > 0 ) {
    ss3.ctl[mg.ch] <- paste(0, "#custom_MG-env_setup (0/1)")
    ss3.ctl[(mg.ch + 1)] <- "-1 2 1 0 -1 99 -2  # env link specification i.e fixed to 1"
    ss3.ctl[grep("#_env/block/dev_adjust_method", ss3.ctl)[1]] <- "1 #_env/block/dev_adjust_method"
  }
  if(subset(tab, lab == "sx", select = "Freq") > 0 ) {
    ss3.ctl[sx.ch] <- paste(0, "#custom_sel-env_setup (0/1)")
    ss3.ctl[(sx.ch + 1)] <- "-1 2 1 0 -1 99 -2 # env link specification i.e fixed to 1"
    ss3.ctl[grep("#_env/block/dev_adjust_method", ss3.ctl)[2]] <- "1 #_env/block/dev_adjust_method"
    }

  temp.data <- change_tv_list[lab == "mg" | lab == "sx"]
for(i in seq_along(temp.data)) {
  dat.varnum.counter <- dat.varnum.counter + 1
  par.ch <- grep(names(temp.data)[i], ss3.ctl, fixed = TRUE)[1]
  par.ex <- regexpr(names(temp.data)[i], ss3.ctl[par.ch])[1]
  val <- strsplit(substr(ss3.ctl[par.ch], start=1, stop=par.ex-1), " ")[[1]]
    # values might include spaces, make them NA and remove
    # should result in a vector with length == 14
    val <- suppressWarnings(as.numeric(val))
    check <- is.na(val)
    if (sum(check) > 0) {
      val <- val[check == FALSE]
        if(length(val) < 14) {
          stop(paste("Please check", names(temp.data)[i], "in the control file,
               because the vector is less than 14 entries."))
        }
    }
    # Set the environmental link (8th element)
    # where abs(link) == variable# in environmental table in ss3.dat
    # negative links use an additive fxn of environmental variable (g)
    # value of g in year y (env(y,-g))
    # param`(y) = param + link*env(y,-g)
    val[8] <- -1 * dat.varnum.counter
    ss3.ctl[par.ch] <- paste(c(val, "#",  names(temp.data)[i]), collapse=" ")
  dat <- data.frame(year = year.beg:year.end,
                    variable = dat.varnum.counter,
                    value = temp.data[i])
  names(dat) <- c("year", "variable", "value")
    ss3.dat.tbl <- rbind(ss3.dat.tbl, dat)
}

temp.data <- change_tv_list[lab == "sr"]
if(length(temp.data) > 0) {
  sr.ch <- grep("#_SR_env_link", ss3.ctl, fixed = TRUE)
  sr.base <- as.numeric(gsub('([0-9]*).*','\\1',ss3.ctl[sr.ch+1]))
  type <- ifelse(grepl("R0", names(temp.data), ignore.case = TRUE) == 1,
                 "virgin",
                 ifelse(grepl("steep", names(temp.data), ignore.case = TRUE) == 1,
                 "steep",
                 ifelse(grepl("dev", names(temp.data), ignore.case = TRUE) == 1, 
                 "devs", "NA")))
  if(type=="NA") {
    stop("Did not recognize the name for the stock recruit parameter
as recruitment deviations, virgin recruitment, or steepness, 
please rename and rerun the scenario")
  }
  if(type == "devs") {
    warning("ss3sim uses annual recruitment deviations and may not work
with a model that ties recruitment deviations to environmental
covariates. If you need to compare the environment to annual
recruitment deviations, the preferred option is to transform the
environmental variable into an age 0 pre-recruit survey. See
page 55 of the SS3 version 3.24f manual for more information.")
  }
  if(length(temp.data) > 1 ) {
    stop("Currently SS3 only allows one stock recruit paramater at a
time, R0 or steepness, to vary with an environmental
covariate.")
  }

  if(sr.base > 0) {
    stop("Currently SS3 does not allow environmental deviations
for multiple stock recruit parameters.
Please remove the environmental covariate from the base OM
and run the scenario again.")
  }

  sr.shortline.ch <- grep("# SR_envlink", ss3.ctl, fixed = TRUE)
  ss3.ctl[sr.shortline.ch] <- "-5 5 1 0 -1 99 -3 # SR_envlink"
  dat.varnum.counter <- dat.varnum.counter + 1
  ss3.ctl[sr.ch] <- paste(dat.varnum.counter, "#_SR_env_link")

  if(length(grep("dev", names(temp.data), fixed = TRUE)) > 0) {
    ss3.ctl[sr.ch+1] <- "1 #_SR_env_target_0=none;1=devs;_2=R0;_3=steepness"
  }
  if(length(grep("R0", names(temp.data), fixed = TRUE)) > 0) {
    ss3.ctl[sr.ch+1] <- "2 #_SR_env_target_0=none;1=devs;_2=R0;_3=steepness"
  }
  if(length(grep("steep", names(temp.data), fixed = TRUE)) > 0) {
    ss3.ctl[sr.ch+1] <- "3 #_SR_env_target_0=none;1=devs;_2=R0;_3=steepness"
  }

  dat <- data.frame(year = year.beg:year.end,
                    variable = dat.varnum.counter,
                    value = temp.data)
    names(dat) <- c("year", "variable", "value")
    ss3.dat.tbl <- rbind(ss3.dat.tbl, dat)
}
  sr.parameter <- which(lab == "sr")
  if(length(sr.parameter) > 0) {
    names(change_tv_list)[sr.parameter] <- "SR_envlink"
  }

  temp.data <- change_tv_list[lab == "qs"]
  paste.into.ctl <- NULL
for(i in seq_along(temp.data)) {
  dat.varnum.counter <- dat.varnum.counter + 1
  ctl.relevant <- grep("#_Q_setup", ss3.ctl) :
                  grep("#_Cond 0 #_If q has random component", ss3.ctl)
  par.ch <- grep(names(temp.data)[i], ss3.ctl, fixed = TRUE)
  par.ch <- par.ch[which(par.ch %in% ctl.relevant)]
  par.ex <- regexpr(names(temp.data)[i], ss3.ctl[par.ch])[1]
  val <- ss3.ctl[par.ch]
  val.name <- strsplit(val, "#")[[1]][2]
  val.pars <- strsplit(val, "#")[[1]][1]
  val.pars <- strsplit(gsub(" ","",val.pars,""),"")[[1]]
  val.pars[2] <- dat.varnum.counter
  ss3.ctl[par.ch] <- paste(paste(val.pars, collapse = " "),
                           "#", val.name, sep = " ")

  names(change_tv_list)[which(names(change_tv_list) ==
                              names(temp.data)[i])] <-
                  paste0("Q_envlink_",
                        which(fleet.names == names(temp.data)[i]),
                        "_", names(temp.data)[i])

  paste.into.ctl <- c(paste.into.ctl,
                      paste("-2 2 1 0 -1 99 -5 #", names(temp.data)[i]))

  dat <- data.frame(year = year.beg:year.end,
                    variable = dat.varnum.counter,
                    value = temp.data[i])
  names(dat) <- c("year", "variable", "value")
    ss3.dat.tbl <- rbind(ss3.dat.tbl, dat)
}
  par.spec <- grep("#_Q_parms\\(if_any\\)", ss3.ctl)
  # Check to see if any Q_parms have a power function,
  # if so change par.spec to place Q_env after Q_power
  par.power<- grep("Q_power_", ss3.ctl, fixed=TRUE)
  par.power<- ifelse(length(par.power) == 0, 0, length(par.power))
  if(!is.null(paste.into.ctl)) ss3.ctl <- append(ss3.ctl,
                                                 paste.into.ctl,
                                                 (par.spec + 1 + par.power))

    ss3.dat.top[grep(" #_N_environ_variables",
                     ss3.dat.top, fixed = TRUE)] <- paste(dat.varnum.counter,
                                                          " #_N_environ_variables")
    ss3.dat.top[grep(" #_N_environ_obs",
                     ss3.dat.top, fixed = TRUE)] <- paste((year.end - year.beg + 1) * dat.varnum.counter,
                                        " #_N_environ_obs")
    ss3.dat.new=c(ss3.dat.top,
                  apply(ss3.dat.tbl, 1, paste, collapse = " "),
                  ss3.dat.bottom)
    writeLines(ss3.dat.new, con = dat_file_out)
    writeLines(ss3.ctl, con= ctl_file_out)

    #run SS with with no estimation and no hessian
    #first change starter file option to use .par to .ctl
    usepar.ch <- grep("# 0=use init values in control file; 1=use ss3.par",
                      ss3.starter, fixed=TRUE)

    ss3.starter[usepar.ch] <- "0 # 0=use init values in control file; 1=use ss3.par"
    ss3.starter[usepar.ch-2] <- dat_file_out
    ss3.starter[usepar.ch-1] <- ctl_file_out
    writeLines(ss3.starter, con = starter_file_out)

    #Call ss3 for a run that includes the environmental link
    os <- .Platform$OS.type
      if(os == "unix") {
        system("SS3 -noest", ignore.stdout = TRUE)
      } else {
        system("SS3 -noest", show.output.on.console = FALSE, invisible = TRUE, ignore.stdout = TRUE)
      }

    #Change starter file option back to using .par!
    ss3.starter[usepar.ch] = "1 # 0=use init values in control file; 1=use ss3.par"
    writeLines(ss3.starter, con = starter_file_out)

  ss3.report <- readLines(con = report_file)
  ss3.par    <- readLines(con = par_file_in)

  env.name <- sapply(names(change_tv_list), function(x) {
                ifelse(grepl("envlink", x),
                       x,
                       paste(x, "ENV", sep = "_"))
              })
  env.parnum <- sapply(env.name, function(x) {
      temp <- grep(x, ss3.report, value = TRUE)
      temp <- strsplit(temp, " ")[[1]][1]
      as.numeric(temp)
    })
    # ensure order is same throughout:
    env.name <- sort(env.parnum)
    env.lab <- sort(lab)
    env.parnum <- sort(env.parnum)
for(q in seq_along(change_tv_list)) {
    if(env.lab[q] == "sr" | env.lab[q] == "qs") next
    if(env.lab[q] == "mg") {
      search.phrase <- paste0("# MGparm[", env.parnum[q] - 1, "]:")
      line.a <- grep(search.phrase, ss3.par, fixed = TRUE)
      add.par <- c(paste0("# MGparm[",env.parnum[q],"]:"),
                   "1.00000000000")
      ss3.par <- append(ss3.par, add.par, (line.a + 1))
          }
    if(env.lab[q] == "sx") {
      num.sx <- grep("Sel_.._", ss3.report )
      pos.sx <- grep(env.name[q], ss3.report[num.sx])
      search.phrase <- paste0("# selparm[", pos.sx - 1, "]:")
      line.a <- grep(search.phrase, ss3.par, fixed = TRUE)
      add.par <- c(paste0("# selparm[",pos.sx,"]:"),
                   "1.00000000000")
      ss3.par <- append(ss3.par, add.par, (line.a + 1))
          } }
    if(any(env.lab == "qs")) {
      qs.relevant <- (max(grep("F_fleet", ss3.report)) + 1) :
                      (grep("Sel_", ss3.report)[1] - 1)
      qs.old  <- sapply(strsplit(ss3.report[qs.relevant], " "),
                        "[[", 3)
      # find the section in the par with the q params
      # delete them
      # put in new words and new vals
      qs.count <- seq_along(qs.old)
      qs.new <- as.vector(rbind(paste0("# Q_parm[", qs.count, "]:"),
                                qs.old))
      ss3.par  <- ss3.par[-(grep("# Q_parm[1]:", ss3.par, fixed = TRUE) :
                 (grep("# selparm[1]:", ss3.par, fixed = TRUE) - 1))]
      ss3.par <- append(ss3.par, qs.new,
                        (grep("# selparm[1]:",
                              ss3.par, fixed = TRUE) - 1))
      }
    if(any(env.lab == "sr")) {
      sr.parnum <- which(grep("SR_envlink", ss3.report) == grep("SR", ss3.report))
      ss3.par[grep(paste0("# SR_parm[", sr.parnum, "]:"),
              ss3.par, fixed = TRUE) + 1 ] <- "1.00000000000"
          }
    writeLines(ss3.par, con = par_file_out)
  }