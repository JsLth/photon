#' Structured geocoding
#' @description
#' Geocode a set of place information such as street, house number, or
#' post code. Structured geocoding is generally more accurate but requires
#' more information than \link[=geocode]{unstructured geocoding}. Note that
#' structured geocoding must be specifically enabled when building a Nominatim
#' database. It is generally not available on komoot's public API and on
#' pre-built search indices through \code{\link{download_searchindex}}.
#'
#' @param .data Dataframe or list containing structured information on a place
#' to geocode. Can contain the columns \code{street}, \code{housenumber},
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
                       locbias = NULL,
                       locbias_scale = NULL,
                       zoom = NULL,
                       debug = FALSE,
                       progress = TRUE
) {
  if (!has_structured_support()) {
    ph_stop("Structured geocoding is disabled the mounted photon instance.")
  }

  cols <- c("street", "housenumber", "postcode", "city", "county", "state", "countrycode")
  assert_class(.data, "data.frame")
  assert_named(.data, cols)
  assert_vector(limit, "double", null = TRUE)
  assert_vector(lang, "character", null = TRUE)
  assert_vector(osm_tag, "character", null = TRUE)
  assert_vector(layer, "character", null = TRUE)
  assert_vector(locbias_scale, "double", null = TRUE)
  assert_vector(zoom, "double", null = TRUE)
  assert_length(limit, null = TRUE)
  assert_length(lang, null = TRUE)
  assert_length(layer, null = TRUE)

  locbias <- format_locbias(locbias)
  bbox <- format_bbox(bbox)

  if (progress) {
    cli::cli_progress_bar(name = "Geocoding", total = NROW(.data))
    env <- environment()
  }

  .data$i <- seq_len(NROW(.data))
  geocoded <- .mapply(dots = .data, MoreArgs = NULL, function(i, ...) {
    if (progress) cli::cli_progress_update(.envir = env)
    res <- structured_impl(
      ...,
      limit = limit,
      lang = lang,
      bbox = bbox,
      osm_tag = osm_tag,
      layer = layer,
      lon = locbias$lon,
      lat = locbias$lat,
      location_bias_scale = locbias_scale,
      zoom = zoom
    )
    cbind(idx = i, res)
  })
  as_data_frame(rbind_list(geocoded))
}


structured_impl <- function(...) {
  args <- list(...)
  req <- httr2::request(get_photon_url())
  req <- httr2::req_template(req, "GET structured")
  req <- do.call(httr2::req_url_query, c(list(.req = req), args))
  req <- throttle(req)

  if (isTRUE(getOption("photon_debug", FALSE))) {
    cli::cli_inform("GET {req$url}")
  }

  resp <- httr2::req_perform(req)
  resp <- httr2::resp_body_string(resp, encoding = "UTF-8")
  sf::st_read(resp, as_tibble = TRUE, quiet = TRUE, drivers = "geojson")
}


is_komoot <- function(url) {
  grepl("photon.komoot.io", url, fixed = TRUE)
}


has_structured_support <- function() {
  url <- get_photon_url()
  if (is_komoot(url)) return(FALSE)

  req <- httr2::request(url)
  req <- httr2::req_template(req, "GET structured")
  req <- httr2::req_error(req, function(r) FALSE)
  resp <- httr2::req_perform(req)
  resp$status_code == 400
}
