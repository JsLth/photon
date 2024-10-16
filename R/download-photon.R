get_all_releases <- function() {
  req <- httr2::request("https://api.github.com/repos/komoot/photon/tags")
  resp <- httr2::resp_body_json(httr2::req_perform(req))
  versions <- vapply(resp, FUN.VALUE = character(1), "[[", "name")
  versions <- drop_na(numeric_version(versions, strict = FALSE))
  sort(versions, decreasing = TRUE)
}


#' Download photon
#' @description
#' Download the photon executable from GitHub.
#'
#' @param path Path to a directory to store the exectutable.
#' @param version Version tag of the photon release.
#' @inheritParams download_searchindex
#'
#' @returns Character string giving the path to the downloaded file.
#'
#' @export
#'
#' @examples
#' if (FALSE) {
#' download_photon(tempdir(), version = "0.4.1")
#' }
download_photon <- function(path = ".", version = NULL, quiet = FALSE) {
  assert_dir(path)
  assert_length(path, 1)
  assert_vector(version, "character", null = TRUE)
  assert_length(version, 1, null = TRUE)
  version <- version %||% get_photon_version()

  if (!quiet) {
    cli::cli_progress_step(
      msg = "Fetching photon {.field {version}}.",
      msg_done = "Successfully downloaded photon {.field {version}}.",
      msg_failed = "Failed to download photon."
    )
  }

  req <- httr2::request("https://github.com/komoot/photon/releases/download/")
  file <- sprintf("photon-%s.jar", version)
  req <- httr2::req_url_path_append(req, version, file)
  path <- file.path(path, file)
  httr2::req_perform(req, path = path)
  normalizePath(path, "/")
}
