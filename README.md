# ss3sim

ss3sim is an R package that simplifies the steps needed to generate beautiful
simulation output from the widely-used [Stock
Synthesis](https://nmfs-ost.github.io/ss3-doc/) (SS3) assessment framework. To
learn more, read on or check out the [Introduction
vignette](https://ss3sim.github.io/ss3sim/articles/introduction.html) on the
[ss3sim website](https://ss3sim.github.io/ss3sim/).

## Table of contents

- [ss3sim](#ss3sim)
  - [Table of contents](#table-of-contents)
  - [Installation](#installation)
  - [Simulation setup](#simulation-setup)
  - [How ss3sim works](#how-ss3sim-works)
    - [Example output from a simulation](#example-output-from-a-simulation)
  - [Citing ss3sim](#citing-ss3sim)
  - [Contributing to ss3sim](#contributing-to-ss3sim)
    - [Code of conduct](#code-of-conduct)
    - [Disclaimer](#disclaimer)

## Installation

Below are instructions for installing ss3sim from GitHub, which is the
preferred approach. Users can use
[remotes](https://github.com/r-lib/remotes),
[devtools](https://github.com/r-lib/devtools), or
[pak](https://github.com/r-lib/pak)
to do this, though the example below is for the latter. `"main"` is the default
branch with the latest code, all developmental features will be in feature
branches.

Install the GitHub version via {pak}:

``` r
# install.packages("pak")
pak::pkg_install("ss3sim/ss3sim")
```

The [CRAN version](https://cran.r-project.org/package=ss3sim) of ss3sim is not
regularly updated, and thus, it is not recommended to install from CRAN. We
suggest using the GitHub version because it comes with the SS3
executable/binary. If you are using the CRAN version, you will need to install
the binary and place it in your system path. See the [SS3 Release
page](https://github.com/nmfs-ost/ss3-source-code/releases) for an executable
that will work on your operating system and the SS3 documentation for [how to
place the executable in your
path](https://nmfs-ost.github.io/ss3-doc/SS330_User_Manual_release.html#putting-stock-synthesis-in-your-path).

Once ss3sim is installed, you can read the help files and access the
[Introduction
vignette](https://ss3sim.github.io/ss3sim/articles/introduction.html)
for reproducible examples of ss3sim. See below for code how to do both.

``` r
?ss3sim
browseVignettes("ss3sim")
vignette("introduction", "ss3sim")
```

## Simulation setup

An ss3sim simulation requires three types of input:

1. a base model of the underlying truth (an SS3 operating model; OM),
1. an SS3 estimation method (EM) to assess the current status, and
1. a data frame specifying how you want to manipulate (1) and (2) from their
   status-quo configurations.

You can find [examples of an OM and EM on
GitHub](https://github.com/ss3sim/ss3sim/tree/master/inst/extdata/models) or
locally on your machine if you have installed ss3sim. To find the location of
these files locally, run `system.file("extdata", "models", package =
"ss3sim")`. Users often modify these files to create new life histories or
modify their own files from a production stock assessment to work within
ss3sim. See the vignettes [on modifying
models](https://ss3sim.github.io/ss3sim/articles/modifying-models.html) and
[making models](https://ss3sim.github.io/ss3sim/articles/making-models.html)
for more information.

An example data frame for (3) is also available within the package via
`ss3sim::setup_scenarios_defaults()`. This example is sufficient to run a
single scenario using the OM and EM supplied in the package. Many more options
(i.e., columns) are possible and users should take note that this example
provided in the package represents a minimum viable setup. Users can either
create their own data frame in R or augment this existing data frame to run a
set of custom scenarios. Specifically, adding columns will enable the
manipulation of additional components of the OM, sampling procedure, or the EM.
Adding rows will lead to more scenarios, where a scenario is the result of the
combination of specifications in that row, i.e., how you manipulate the OM and
the EM.

ss3sim stores each scenario in its own directory. Inside the scenario directory
will be one directory per iteration. Iterations within a scenario differ only
by the seed used within R to define the randomness of that iteration. See the
figure below for an example directory structure from a simulation with two
scenarios and 3 iterations.

``` text
├📁 scenario 1
│   ├📁  1
│   │    ├📁  OM
│   │    └📁  EM
│   ├📁  2
│   │    ├📁  OM
│   │    └📁  EM
│   └📁  3
│        ├📁  OM
│        └📁  EM
└📁 scenario 2
    ├📁  1
    │     ├📁  OM
    │     └📁  EM
    ├📁  2
    │     ├📁  OM
    │     └📁  EM
    └📁  3
         ├📁  OM
         └📁  EM
```

## How ss3sim works

ss3sim works by converting information stored in the columns of your data frame
that stores your simulation specifications (e.g., `example_df_configuration`)
into function arguments. Functions within the ss3sim package use these
arguments to manipulate the associated OM and EM files such that the
appropriate simulated data is generated and used to fit the EM. For example,
the first row of the simulation argument for the observation error of the index
might be equal to 0.4 if you want a noisy survey

``` r
example_df_configuration <- ss3sim::setup_scenarios_defaults()
example_df_configuration[1, "si.sds_obs.2"] <- 0.4
```

ss3sim functions are divided into the following three types of functions:

1. `change` and `sample` functions that manipulate SS3 configuration files.
   These manipulations generate the underlying "truth" (OMs) and control the
   assessment of the truth (EMs).
2. `run` functions that conduct simulations. These functions generate a folder
   structure, call manipulation functions, run SS3 as needed, and save the
   output.
3. `get` functions that synthesize the output.

### Example output from a simulation

```r
data("scalar_dat", package = "ss3sim")
p <- scalar_dat |>
  dplyr::mutate(
    M = ifelse(NatM_p_1_Fem_GP_1 == 0.2, "M = 0.2", "M = Estimated")
  ) |>
  dplyr::filter(model_run == "em") |>
  ggplot2::ggplot(ggplot2::aes(x = LnQ_base_Survey_2, y = depletion)) +
  ggplot2::geom_point() +
  ggplot2::facet_grid("M") +
  ggplot2::xlab("Survey scalar (q)") +
  ggplot2::ylab("Depletion")
print(p)
```

You can run the code below to visualize the results of a simulation with two
scenarios, one that fixed natural mortality (*M*) at its true value from the OM
(*M* = 0.2) and one that estimated *M*. The upper panel shows how the estimates
depletion change as the estimate of *q* changes for when *M* is fixed at the
truth and the lower panel shows the same relationship when *M* is estimated.

## Citing ss3sim

If you use ss3sim in a publication, please cite it as shown by

``` r
citation("ss3sim")
toBibtex(citation("ss3sim"))
```

## Contributing to ss3sim

Interested in contributing to ss3sim? We recognize and appreciate that
contributions come in many forms, including but not limited to writing code,
reporting issues, and creating examples and/or documentation.

We strive to follow the [NMFS Fisheries Toolbox Contribution
Guide](https://github.com/nmfs-fish-tools/Resources/blob/master/CONTRIBUTING.md).
We also have included ss3sim-specific code contribution information in the
[Developers page of the ss3sim
wiki](https://github.com/ss3sim/ss3sim/wiki/developers). Note that these are
guidelines, not rules, and we are open to collaborations in other ways that may
work better for you. Please feel free to reach out to us by opening an issue in
this repository or by emailing the maintainer (run `maintainer("ss3sim")` in R
to view the current maintainer's name and email address).

Note that contributors are expected to uphold the [code of conduct](#code-of-conduct).

### Code of conduct

This project and everyone participating in it is governed by the [NMFS
Fisheries Toolbox Code of
Conduct](https://github.com/nmfs-fish-tools/Resources/blob/master/CODE_OF_CONDUCT.md).
By participating, you are expected to uphold this code. Please report
unacceptable behavior to
[fisheries.toolbox@noaa.gov](mailto:fisheries.toolbox@noaa.gov). Note that the
maintainers of ss3sim do not have access to this email account, so unacceptable
behavior of maintainers can also be reported here.

The NFMS Fisheries Toolbox Code of Conduct is adapted from the [Contributor
Covenant][[homepage](https://www.contributor-covenant.org)], version 1.4,
available at
<https://www.contributor-covenant.org/version/1/4/code-of-conduct.html>.

### Disclaimer

"The United States Department of Commerce (DOC) GitHub project code is provided
on an 'as is' basis and the user assumes responsibility for its use. DOC has
relinquished control of the information and no longer has responsibility to
protect the integrity, confidentiality, or availability of the information. Any
claims against the Department of Commerce stemming from the use of its GitHub
project will be governed by all applicable Federal law. Any reference to
specific commercial products, processes, or services by service mark,
trademark, manufacturer, or otherwise, does not constitute or imply their
endorsement, recommendation or favoring by the Department of Commerce. The
Department of Commerce seal and logo, or the seal and logo of a DOC bureau,
shall not be used in any manner to imply endorsement of any commercial product
or activity by DOC or the United States Government."

[U.S. Department of Commerce](https://www.commerce.gov/) | [National
Oceanographic and Atmospheric Administration](https://www.noaa.gov) | [NOAA
Fisheries](https://www.fisheries.noaa.gov/)
