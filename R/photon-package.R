#' @section Terms of use:
#' From \url{https://photon.komoot.io} on using the public API:
#'
#' \emph{"You can use the API for your project, but please be fair - extensive usage
#' will be throttled. We do not guarantee for the availability and usage might
#' be subject of change in the future."}
#'
#' Note that these terms only apply to the public API
#' (\code{\link[=new_photon]{new_photon()}}), and not to local instances
#' (e.g. \code{\link[=new_photon]{new_photon(path = ".")}})! For the public
#' API, the package sets a default of 1 request per second (see below).
#'
#'
#' @section Global options:
#' A number of global options can be set that change the behavior of package
#' functions. These include:
#'
#' \describe{
#'  \item{\code{photon_throttle}}{Rate limit used to throttle requests.
#'  By default, no throttle is set for non-komoot instances. For komoot's
#'  public API, this option defaults to 1 request per second. See
#'  \code{\link[httr2]{req_throttle}}.}
#'  \item{\code{photon_max_tries}}{Number of retries a failing request should
#'  do before ultimately aborting. Defaults to 3. See
#'  \code{\link[httr2]{req_retry}}.}
#'  \item{\code{photon_debug}}{Whether to echo the command of external
#'  processes and GET requests sent to photon. Defaults to \code{FALSE}.}
#' }
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL

PHOTON_VERSION <- "0.5.0"
