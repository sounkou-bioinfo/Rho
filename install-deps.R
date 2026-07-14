configured_repos <- getOption("repos")
configured_repos[configured_repos == "@CRAN@"] <- "https://cloud.r-project.org"
repos <- c(
  sounkou = "https://sounkou-bioinfo.r-universe.dev",
  configured_repos
)
repos <- repos[!duplicated(unname(repos))]
install.packages(
  c(
    "S7",
    "s7contract",
    "nanonext",
    "mirai",
    "coro",
    "later",
    "promises",
    "tinytest",
    "knitr",
    "rmarkdown",
    "pkgdown",
    "rdocdump",
    "roxygen2",
    "yyjsonr",
    "base64enc",
    "digest",
    "processx",
    "DBI",
    "duckdb",
    "ggplot2",
    "svglite",
    "ragg"
  ),
  repos = repos
)
