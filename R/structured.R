#' Structured geocoding
#' @description
#' Geocode a set of place information such as street, house number, or
#' post code. Structured geocoding is generally more accurate but requires
#' more information than \link[=geocode]{unstructured geocoding}. Note that
#' structured geocoding is not available on Komoot's public API.
#'
#' @param .data Dataframe containing structured information on a place to
#' geocode. Can contain the columns \code{street}, \code{housenumber},
#' \code{postcode}, \code{city}, \code{district}, \code{county}, \code{state},
#' and \code{countrycode}. At least one of these columns must be present in the
#' dataframe.
#' @inheritParams geocode
#' @inherit geocode details
#'
#' @export
structured <- function(.data,
                       limit = 3,
                       lang = "en",
                       bbox = NULL,
                       osm_tag = NULL,
                       layer = NULL,
                       location_bias = NULL,
                       location_bias_scale = NULL,
                       zoom = NULL,
                       debug = FALSE
) {

}
