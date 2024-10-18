#' Unstructured geocoding
#' @description
#' Geocode arbitrary text strings. Unstructured geocoding is more flexible but
#' generally less accurate than \link[=structured]{structured geocoding}.
#'
#' @param texts Character vector of a texts to geocode.
#' @param limit Number of results to return. Defaults to 3.
#' @param lang Language of the results.
#' @param bbox Any object that can be parsed by \code{\link[sf]{st_bbox}}.
#' Results must lie within this bbox.
#' @param osm_tag Character string giving an
#' \href{https://wiki.openstreetmap.org/wiki/Tags}{OSM tag} to filter the
#' results by. See details.
#' @param layer Character string giving a layer to filter the results by.
#' Can be one of \code{"house"}, \code{"street"}, \code{"locality"},
#' \code{"district"}, \code{"city"}, \code{"county"}, \code{"state"},
#' \code{"country"}, or \code{"other"}.
#' @param locbias Numeric vector of length 2 or an \code{sfg} point
#' geometry that specifies a location bias for geocoding. Geocoding results
#' are biased towards this point. The radius of the bias is controlled through
#' \code{zoom} and its prominence through \code{location_bias_scale}.
#' @param locbias_scale Numeric vector specifying the prominence of
#' point in \code{location_bias}. Defaults to 0.2.
#' @param zoom Numeric vector specifying the radius of the \code{location_bias}.
#' Corresponds to the zoom level in OpenStreetMap. Defaults to 16.
#' @param progress If \code{TRUE}, shows a progress bar for longer queries.
#'
#' @returns An sf dataframe or tibble containing the following columns:
#'
#' \itemize{
#'  \item{\code{id}: Internal ID specifying the index of the \code{texts}
#'  parameter.}
#'  \item{\code{osm_type}: Type of OSM element, one of N (node), W (way),
#'  R (relation), or P (polygon).}
#'  \item{\code{osm_id}: OpenStreetMap ID of the matched element.}
#'  \item{\code{country}: Country of the matched place.}
#'  \item{\code{city}: City of the matched place.}
#'  \item{\code{osm_key}: OpenStreetMap key.}
#'  \item{\code{countrycode}: ISO2 country code.}
#'  \item{\code{housenumber}: House number, if applicable.}
#'  \item{\code{postcode}: Post code, if applicable.}
#'  \item{\code{locality}: Locality, if applicable.}
#'  \item{\code{street}: Street, if applicable.}
#'  \item{\code{district}: District name, if applicable.}
#'  \item{\code{osm_value}: OpenStreetMap tag value.}
#'  \item{\code{name}: Place name.}
#'  \item{\code{type}: Layer type as described for the \code{layer} parameter.}
#'  \item{\code{extent}: Boundary box of the match.}
#' }
#'
#' @details
#' Filtering by OpenStreetMap tags follows a distinct syntax explained on
#' \url{https://github.com/komoot/photon}. In particular:
#'
#' \itemize{
#'  \item{Include places with tag: \code{key:value}}
#'  \item{Exclude places with tag: \code{!key:value}}
#'  \item{Include places with tag key: \code{key}}
#'  \item{Include places wih tag value: \code{:value}}
#'  \item{Exclude places with tag key: \code{!key}}
#'  \item{Exclude places with tag value: \code{:!value}}
#' }
#'
#' @export
#'
#' @examples
#' \donttest{
#' # an instance must be mounted first
#' photon <- new_photon()
#'
#' # geocode a city
#' geocode("Berlin")
#'
#' # return more results
#' geocode("Berlin", limit = 10)
#'
#' # return the results in german
#' geocode("Berlin", limit = 10, lang = "de")
#'
#' # limit to cities
#' geocode("Berlin", layer = "city")
#'
#' # limit to European cities
#' geocode("Berlin", bbox = c(xmin = -71.18, ymin = 44.46, xmax = 13.39, ymax = 52.52))
#'
#' # search for museums in berlin
#' geocode("Berlin", osm_tag = "tourism:museum")
#'
#' # search for touristic attractions in berlin
#' geocode("Berlin", osm_tag = "tourism")
#'
#' # search for anything but tourism
#' geocode("Berlin", osm_tag = "!tourism")
#' }
geocode <- function(texts,
                    limit = 3,
                    lang = "en",
                    bbox = NULL,
                    osm_tag = NULL,
                    layer = NULL,
                    locbias = NULL,
                    locbias_scale = NULL,
                    zoom = NULL,
                    progress = interactive()) {
  assert_vector(texts, "character")
  assert_vector(limit, "double", null = TRUE)
  assert_vector(lang, "character", null = TRUE)
  assert_vector(osm_tag, "character", null = TRUE)
  assert_vector(layer, "character", null = TRUE)
  assert_vector(locbias_scale, "double", null = TRUE)
  assert_vector(zoom, "double", null = TRUE)
  assert_length(limit, null = TRUE)
  assert_length(lang, null = TRUE)
  assert_length(layer, null = TRUE)
  assert_range(locbias_scale, min = 0, max = 1, than = FALSE)

  locbias <- format_locbias(locbias)
  bbox <- format_bbox(bbox)

  if (progress && globally_enabled("photon_movers")) {
    cli::cli_progress_bar(name = "Geocoding", total = length(texts))
  }

  options <- list(env = environment())
  iter <- list(q = texts, i = seq_len(length(texts)))
  geocoded <- .mapply(iter, MoreArgs = options, FUN = geocode_impl)
  as_sf(rbind_list(geocoded))
}


geocode_impl <- function(q, i, env, progress) {
  if (env$progress) cli::cli_progress_update(.envir = env)
  res <- query_photon(
    endpoint = "api",
    q = q,
    limit = env$limit,
    lang = env$lang,
    bbox = env$bbox,
    osm_tag = env$osm_tag,
    layer = env$layer,
    lon = env$locbias$lon,
    lat = env$locbias$lat,
    location_bias_scale = env$locbias_scale,
    zoom = env$zoom
  )
  cbind(idx = rep(i, nrow(res)), res)
}


format_bbox <- function(bbox) {
  if (!is.null(bbox)) {
    bbox <- sf::st_bbox(bbox)
    bbox <- paste(bbox, collapse = ",")
  }
  bbox
}


format_locbias <- function(locbias) {
  if (!is.null(locbias)) {
    locbias <- as.numeric(locbias)
    locbias = list(lon = locbias[1], lat = locbias[2])
  }
  locbias
}


throttle <- function(req) {
  rate <- getOption("photon_throttle")
  if (is_komoot(req$url) || !is.null(rate)) {
    dflt <- 60 / 60
    req <- httr2::req_throttle(req, rate = rate %||% dflt)
  }
  req
}


query_photon <- function(endpoint, ...) {
  args <- list(...)
  req <- httr2::request(get_photon_url())
  req <- httr2::req_template(req, "GET {endpoint}")
  req <- do.call(httr2::req_url_query, c(list(.req = req), args))
  req <- throttle(req)

  if (globally_enabled("photon_debug")) { # nocov start
    cli::cli_inform("GET {req$url}")
  } # nocov end

  resp <- httr2::req_perform(req)
  resp <- httr2::resp_body_string(resp, encoding = "UTF-8")
  sf::st_read(resp, as_tibble = TRUE, quiet = TRUE, drivers = "geojson")
}
