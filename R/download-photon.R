#' Download photon
#' @description
#' Download the photon executable from GitHub.
#'
#' @param path Path to a directory to store the executable.
#' @param version Version tag of the photon release. If \code{NULL},
#' downloads the latest known version. A list of all
#' releases can be found here: \url{https://github.com/komoot/photon/releases/}.
#' Ignored if \code{jar} is given. If \code{NULL}, uses the latest known
#' version (Currently: `r get_latest_photon()`).
#' @param opensearch If \code{TRUE}, downloads the OpenSearch version of
#' photon if available. OpenSearch versions are available for photon >= 0.6.0.
#' Since photon >= 0.7.0, OpenSearch versions are recommended. Defaults to
#' \code{TRUE}.
#' @inheritParams download_searchindex
#'
#' @returns If \code{only_url = FALSE}, returns a character string giving the
#' path to the downloaded file. Otherwise, returns the URL to be downloaded.
#'
#' @export
#'
#' @examples
#' \donttest{download_photon(tempdir(), version = "0.4.1")}
download_photon <- function(path = ".",
                            version = NULL,
                            opensearch = TRUE,
                            only_url = FALSE,
                            quiet = FALSE) {
  assert_dir(path)
  assert_vector(version, "character", size = 1, null = TRUE)
  assert_flag(opensearch)
  assert_flag(only_url)
  assert_flag(quiet)
  version <- version %||% get_latest_photon()

  if (opensearch && !minimum_version(version, "0.6.0")) {
    ph_stop(c(
      "OpenSearch versions of photon are only available for photon >= 0.6.0.",
      "i" = "For earlier versions, you have to build it yourself using gradle."
    ), class = "opensearch_unsupported")
  }

  if (!quiet) {
    type <- ifelse(opensearch, "OpenSearch", "ElasticSearch")
    cli::cli_progress_step(
      msg = "Fetching {type} photon {.field {version}}.",
      msg_done = "Successfully downloaded {type} photon {.field {version}}.",
      msg_failed = "Failed to download {type} photon."
    )
  }

  req <- httr2::request("https://github.com/komoot/photon/releases/download/")
  file <- build_photon_name(version, opensearch)
  req <- httr2::req_url_path_append(req, version, file)
  req <- httr2::req_retry(req, max_tries = getOption("photon_max_tries", 3))

  if (globally_enabled("photon_movers")) {
    req <- httr2::req_progress(req)
  }

  path <- file.path(path, file)
  httr2::req_perform(req, path = path)
  normalizePath(path, "/")
}
