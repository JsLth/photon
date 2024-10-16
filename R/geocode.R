#' Unstructured geocode
#' @description
#' Geocode an arbitrary text string.
#'
#' @param text Character string of a text to geocode.
#' @param limit Number of results to return. Defaults to 3.
#' @param lang Language of the results
#' @param bbox Any object that can be parsed by \code{\link[sf]{st_bbox}}.
#' Results must lie within this bbox.
#' @param osm_tag Character string giving an
#' \href{https://wiki.openstreetmap.org/wiki/Tags}{OSM tag} to filter the
#' results by. See details.
#' @param layer Character string giving a layer to filter the results by.
#' Can be one of \code{"house"}, \code{"street"}, \code{"locality"},
#' \code{"district"}, \code{"city"}, \code{"county"}, \code{"state"},
#' \code{"country"}, or \code{"other"}.
#'
#' @details
#' Additional details...
#'
#' @export
#'
#' @examples
#' if (FALSE) {
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
#' }
geocode <- function(text,
                    limit = 3,
                    lang = "en",
                    bbox = NULL,
                    osm_tag = NULL,
                    layer = NULL) {
  if (!is.null(bbox)) {
    bbox <- sf::st_bbox(bbox)
    bbox <- paste(bbox, collapse = ",")
  }

  req <- httr2::request(get_photon_url())
  req <- httr2::req_template(req, "GET api")
  req <- httr2::req_error(req, is_error = function(r) FALSE)
  req <- httr2::req_url_query(
    req,
    q = text,
    limit = limit,
    lang = lang,
    bbox = bbox,
    osm_tag = osm_tag,
    layer = layer
  )

  resp <- httr2::req_perform(req)
  resp <- httr2::resp_body_string(resp, encoding = "UTF-8")
  sf::st_read(resp, as_tibble = TRUE, quiet = TRUE, drivers = "geojson")
}
