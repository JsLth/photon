#' Initialize a photon instance
#' @description
#' Initialize a photon instance by creating a new photon object. This object
#' is stored in the R session and can be used to perform geocoding requests.
#'
#' Instances can either local or remote. Remote instances require nothing more
#' than a URL that geocoding requests are sent to. Local instances require the
#' setup of the photon executable, a search index, and Java. See
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
#' @param country Character string that can be identified by
#' \code{\link[countrycode]{countryname}} as a country. An extract for this
#' country will be downloaded. If \code{NULL}, downloads a global search index.
#' @param date Character string or date-time object used to specify the creation
#' date of the search index. If \code{"latest"}, will download the file tagged
#' with "latest". If a character string, the value should be parseable by
#' \code{\link{as.POSIXct}}. If \code{exact = FALSE}, the input value is
#' compared to all available dates and the closest date will be selected.
#' Otherwise, a file will be selected that exactly matches the input to
#' \code{date}.
#' @param opensearch If \code{TRUE}, looks for an OpenSearch version of
#' photon in the specified path. Opensearch-based photon supports structured
#' geocoding queries but is currently only experimental. Defaults to
#' \code{FALSE}. See \code{vignette("nominatim-import", package = "photon")}
#' for details.
#' @param exact If \code{TRUE}, exactly matches the \code{date}. Otherwise,
#' selects the date with lowest difference to the \code{date} parameter.
#' @param section Subdirectory of the download server from which to select a
#' search index. If \code{"experimental"}, selects a dump made for the master
#' version of photon. If \code{"archived"}, selects a dump made for an older
#' version of photon. If \code{NULL} (or any arbitrary string), selects a
#' dump made for the current release. Defaults to \code{NULL}.
#' @param overwrite If \code{TRUE}, overwrites existing jar files and
#' search indices when initializing a new instance. Defaults to
#' \code{FALSE}.
#' @param quiet If \code{TRUE}, suppresses all informative messages.
#'
#' @returns An R6 object of class \code{photon}.
#'
#' @export
#'
#' @examples
#' # connect to public API
#' photon <- new_photon()
#'
#' # connect to arbitrary server
#' photon <- new_photon(url = "photonserver.org")
#'
#' \donttest{
#' if (has_java("11")) {
#' # set up a local instance in the current working directory
#' photon <- new_photon("photon", country = "Ireland")
#' photon$remove_data() # cleanup
#' }}
new_photon <- function(path = NULL,
                       url = NULL,
                       photon_version = NULL,
                       country = NULL,
                       date = "latest",
                       exact = FALSE,
                       section = NULL,
                       opensearch = FALSE,
                       overwrite = FALSE,
                       quiet = FALSE) {
  if (is.null(path) && is.null(url)) {
    photon_remote$new(url = "https://photon.komoot.io/")
  } else if (is.null(path)) {
    photon_remote$new(url = url)
  } else if (is.null(url)) {
    photon_local$new(
      path = path,
      photon_version = photon_version,
      country = country,
      date = date,
      exact = exact,
      section = section,
      opensearch = opensearch,
      overwrite = overwrite,
      quiet = quiet
    )
  }
}


photon_env <- new.env(parent = emptyenv())


photon_cache <- function() {
  get("photon_env", envir = asNamespace("photon"))
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
