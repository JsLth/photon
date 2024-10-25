#' Structured geocoding
#' @description
#' Geocode a set of place information such as street, house number, or
#' post code. Structured geocoding is generally more accurate but requires
#' more information than \link[=geocode]{unstructured geocoding}.
#'
#' Note that structured geocoding must be specifically enabled when building a
#' Nominatim database. It is generally not available on komoot's public API and
#' on pre-built search indices through \code{\link{download_searchindex}}. See
#' \code{vignette("nominatim-import", package = "photon")} for details. You can
#' use the helper function \code{has_structured_support()} to check if the
#' current API supports structured geocoding.
#'
#' @param .data Dataframe or list containing structured information on a place
#' to geocode. Can contain the columns \code{street}, \code{housenumber},
#' \code{postcode}, \code{city}, \code{district}, \code{county}, \code{state},
#' and \code{countrycode}. At least one of these columns must be present in the
#' dataframe. Note that countries must be passed as ISO-2 country codes.
#' @inheritParams geocode
#' @inherit geocode details
#' @inherit geocode return
#'
#' @export
#'
#' @examples
#' if (FALSE) {
#' # structured() requires an OpenSearch instance with structured support
#' # the following code will not work off the shelf
#' # refer to vignette("nominatim-import") for details
#' dir <- file.path(tempdir(), "photon")
#' photon <- new_photon(dir, opensearch = TRUE)
#' photon$import(password = "psql_password", structured = TRUE)
#' photon$start()
#'
#' # check if structured() is supported
#' has_structured_support()
#'
#' # structured() works on dataframes containing structurized data
#' place_data <- data.frame(
#'   housenumber = c(NA, "77C", NA),
#'   street = c("Falealilli Cross Island Road", "Main Beach Road", "Le Mafa Pass Road"),
#'   state = c("Tuamasaga", "Tuamasaga", "Atua")
#' )
#' structured(place_data, limit = 1)
#'
#' # countries must be specified as iso2 country codes
#' structured(data.frame(countrycode = "ws"))
#'
#' # traditional parameters from geocode() can also be used but are much more niche
#' structured(data.frame(city = "Apia"), layer = "house") # matches nothing
#'
#' # structured geocoding can discern small differences in places
#' safune <- data.frame(
#'   city = c("Safune", "Safune"),
#'   state = c("Gagaʻifomauga", "Tuamasaga")
#' )
#' structured(safune, limit = 1)
#' }
structured <- function(.data,
                       limit = 3,
                       lang = "en",
                       bbox = NULL,
                       osm_tag = NULL,
                       layer = NULL,
                       locbias = NULL,
                       locbias_scale = NULL,
                       zoom = NULL,
                       progress = interactive()
) {
  if (!has_structured_support()) {
    ph_stop("Structured geocoding is disabled for the mounted photon instance.")
  }

  cols <- c("street", "housenumber", "postcode", "city", "county", "state", "countrycode")
  assert_class(.data, c("data.frame", "list"))
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
  assert_flag(progress)
  progress <- progress && globally_enabled("photon_movers")

  locbias <- format_locbias(locbias)
  bbox <- format_bbox(bbox)
  .data <- as.data.frame(.data)

  if (progress) {
    cli::cli_progress_bar(name = "Geocoding", total = nrow(.data))
    env <- environment()
  }

  options <- list(env = environment())
  .data$i <- seq_len(nrow(.data))
  geocoded <- .mapply(.data, MoreArgs = options, FUN = structured_impl)
  as_sf(rbind_list(geocoded))
}


structured_impl <- function(i, ..., env) {
  if (env$progress) cli::cli_progress_update(.envir = env)
  res <- query_photon(
    endpoint = "structured",
    ...,
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


is_komoot <- function(url) {
  grepl("photon.komoot.io", url, fixed = TRUE)
}


#' @rdname structured
#' @export
has_structured_support <- function() {
  url <- get_photon_url()
  if (is_komoot(url)) return(FALSE)

  req <- httr2::request(url)
  req <- httr2::req_template(req, "GET structured")
  req <- httr2::req_error(req, function(r) FALSE)
  resp <- httr2::req_perform(req)
  resp$status_code == 400
}
