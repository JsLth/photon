#' Initialize a photon instance
#' @description
#' Initialize a photon instance by creating a new photon object. This object
#' is stored in the R session and can be used to perform geocoding requests.
#'
#' Instances can either be local or remote. Remote instances require nothing
#' more than a URL that geocoding requests are sent to. Local instances require
#' the setup of the photon executable, a search index, and Java. See
#' \code{\link{photon_local}} for details.
#'
#' @param path Path to a directory where the photon executable and data
#' should be stored. Defaults to a directory "photon" in the current
#' working directory. If \code{NULL}, a remote instance is set up based on
#' the \code{url} parameter.
#' @param url URL of a photon server to connect to. If \code{NULL} and
#' \code{path} is also \code{NULL}, connects to the public API under
#' \url{https://photon.komoot.io/}.
#' @param photon_version Version of photon to be used. A list of all
#' releases can be found here: \url{https://github.com/komoot/photon/releases/}.
#' Ignored if \code{jar} is given. If \code{NULL}, uses the latest known
#' version.
#' @param opensearch If \code{TRUE}, attempts to download the OpenSearch
#' version of photon. OpenSearch-based photon supports structrued geocoding.
#' Readily available OpenSearch photon executables are only offered since
#' photon version 0.6.0. For earlier versions, you need to build it from
#' source using gradle. In this case, if \code{TRUE}, will look for an
#' OpenSearch version of photon in the specified path. Since photon version
#' 0.7.0, OpenSearch is the recommended option. Defaults to \code{TRUE}.
#' @param mount If \code{TRUE}, mounts the object to the session so that
#' functions like \code{\link{geocode}} automatically detect the new
#' instance. If \code{FALSE}, initializies the instance but doesn't mount
#' it to the session. Defaults to \code{TRUE}.
#' @param overwrite If \code{TRUE}, overwrites existing jar files and
#' search indices when initializing a new instance. Defaults to
#' \code{FALSE}.
#' @param quiet If \code{TRUE}, suppresses all informative messages.
#' @inheritParams download_database
#'
#' @returns An R6 object of class \code{photon}.
#'
#' @export
#'
#' @examplesIf getFromNamespace("is_online", "photon")("graphhopper.com") && getFromNamespace("photon_run_examples", "photon")()
#' # connect to public API
#' photon <- new_photon()
#'
#' # connect to arbitrary server
#' photon <- new_photon(url = "https://photonserver.org")
#'
#' if (has_java("11")) {
#'   # set up a local instance in a temporary directory
#'   dir <- file.path(tempdir(), "photon")
#'   photon <- new_photon(dir, region = "Andorra")
#'   photon$purge(ask = FALSE)
#' }
new_photon <- function(path = NULL,
                       url = NULL,
                       photon_version = NULL,
                       region = NULL,
                       opensearch = TRUE,
                       mount = TRUE,
                       overwrite = FALSE,
                       quiet = FALSE) {
  if (is.null(path) && is.null(url)) {
    photon_remote$new(url = "https://photon.komoot.io/", mount = mount)
  } else if (is.null(path)) {
    photon_remote$new(url = url, mount = mount)
  } else if (is.null(url)) {
    photon_local$new(
      path = path,
      photon_version = photon_version,
      region = region,
      opensearch = opensearch,
      mount = mount,
      overwrite = overwrite,
      quiet = quiet
    )
  }
}


photon_env <- new.env(parent = emptyenv())


photon_cache <- function() {
  get("photon_env", envir = asNamespace("photon"))
}


#' Local photon instances
#' @description
#' Evaluate R code with a photon instance without changing the active photon
#' mount.
#'
#' @param photon An object of class \code{\link[=new_photon]{photon}} that is
#' temporarily mounted to the session.
#' @param code Code to execute in the temporary environment.
#'
#' @returns The results of the evaluation of the \code{code} argument.
#'
#' @export
#'
#' @examples
#' # Get a public instance
#' pub_photon <- new_photon()
#'
#' # Mount a custom instance
#' new_photon(url = "https://localhost:8001/")
#'
#' # Geocode with the public instance only once
#' with_photon(pub_photon, geocode("Rutland"))
#'
#' # The custom instance is still mounted
#' get_instance()
with_photon <- function(photon, code) {
  old <- get0("instance", envir = photon_cache())
  on.exit(assign("instance", old, envir = photon_cache()))
  photon$mount()
  force(code)
}


#' Photon utilities
#' @description
#' Utilities to manage photon instances. These functions operate on mounted
#' photon instances which can be initialized using \code{\link{new_photon}}.
#'
#' \itemize{
#'  \item{\code{get_instance()} retrieves the active photon instance.}
#'  \item{\code{get_photon_url()} retrieves the photon URL to send requests.}
#' }
#'
#' @returns \code{get_instance} returns a R6 object of class \code{photon}.
#' \code{get_photon_url()} returns a URL string.
#'
#' @export
#'
#' @examples
#' # make a new photon instance
#' new_photon()
#'
#' # retrieve it from the cache
#' get_instance()
#'
#' # get the server url
#' get_photon_url()
get_instance <- function() {
  instance <- get0("instance", envir = photon_cache())

  if (is.null(instance)) {
    ph_stop(c(
      "x" = "No photon instance found.",
      "i" = "You can start a new instance using {.code new_photon()}."
    ), class = "instance_missing")
  }

  instance
}


#' @rdname get_instance
#' @export
get_photon_url <- function() {
  instance <- get_instance()
  instance$get_url()
}


clear_cache <- function() {
  rm(list = ls(envir = photon_cache()), envir = photon_cache())
}


photon <- R6::R6Class(classname = "photon")
