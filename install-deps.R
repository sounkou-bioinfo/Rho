configured_repos <- getOption("repos")
configured_repos[configured_repos == "@CRAN@"] <- "https://cloud.r-project.org"
repos <- c(
  sounkou = "https://sounkou-bioinfo.r-universe.dev",
  configured_repos
)
repos <- repos[!duplicated(unname(repos))]

nanonext_commit <- "ea905e4919162b9ed6c993953f1b4ee04c98b2e5"
nanonext_source <- sprintf(
  "https://github.com/sounkou-bioinfo/nanonext/archive/%s.tar.gz",
  nanonext_commit
)

install.packages(nanonext_source, repos = NULL, type = "source")
if (!"ncurl_stream_aio" %in% getNamespaceExports("nanonext")) {
  stop("Pinned nanonext build does not export ncurl_stream_aio", call. = FALSE)
}
install.packages(
  c(
    "S7",
    "s7contract",
    "mirai",
    "coro",
    "later",
    "promises",
    "tinytest",
    "knitr",
    "rmarkdown",
    "litedown",
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
