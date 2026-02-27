#' Structured geocoding
#' @description
#' Geocode a set of place information such as street, house number, or
#' post code. Structured geocoding is generally more accurate but requires
#' more information than \link[=geocode]{unstructured geocoding}.
#'
#' You can use the helper function \code{has_structured_support()} to check if
#' the current API supports structured geocoding. Structured geocoding should
#' be enabled on the public photon instance and all photon instances >= 1.0.0,
#' but older versions usually have structured queries disabled.
#'
#' @param .data Dataframe or list containing structured information on a place
#' to geocode. Can contain the columns \code{street}, \code{housenumber},
#' \code{postcode}, \code{city}, \code{district}, \code{county}, \code{state},
#' and \code{countrycode}. At least one of these columns must be present in the
#' dataframe. Country names are automatically converted to ISO-2 codes where
#' possible.
#' @inheritParams geocode
#' @inherit geocode details
#' @inherit geocode return
#'
#' @export
#'
#' @examples
#' \donttest{
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
#'   city = c("Berlin", "Berlin"),
#'   countrycode = c("DE", "US")
#' )
#' structured(safune, limit = 1)
#' }
structured <- function(.data,
                       limit = 1,
                       lang = "en",
                       bbox = NULL,
                       osm_tag = NULL,
                       layer = NULL,
                       locbias = NULL,
                       locbias_scale = NULL,
                       zoom = NULL,
                       dedupe = TRUE,
                       include = NULL,
                       exclude = NULL,
                       progress = interactive()) {
  if (!has_structured_support()) {
    ph_stop("Structured geocoding is disabled for the mounted photon instance.")
  }

  cols <- c("street", "housenumber", "postcode", "city", "county", "state", "countrycode")
  assert_class(.data, c("data.frame", "list"))
  assert_named(.data, cols)
  assert_vector(limit, "numeric", size = 1, null = TRUE)
  assert_vector(lang, "character", size = 1)
  assert_vector(osm_tag, "character", null = TRUE)
  assert_vector(layer, "character", null = TRUE)
  assert_vector(locbias_scale, "numeric", size = 1, null = TRUE)
  assert_vector(zoom, "numeric", size = 1, null = TRUE)
  assert_vector(include, "character", null = TRUE)
  assert_vector(exclude, "character", null = TRUE)
  assert_range(locbias_scale, min = 0, max = 1, than = FALSE)
  assert_flag(dedupe)
  assert_flag(progress)
  progress <- progress && globally_enabled("photon_movers")

  if ("countrycode" %in% names(.data)) {
    .data$countrycode <- try_iso2(.data$countrycode)
  }

  locbias <- format_locbias(locbias)
  bbox <- format_bbox(bbox)
  include <- format_csv(include)
  exclude <- format_csv(exclude)
  cols <- intersect(cols, names(.data))
  query <- as.data.frame(.data)[cols]
  gids <- group_id(query)
  options <- list(env = environment())

  if (progress) {
    cli::cli_progress_bar(name = "Geocoding", total = nrow(query))
  }

  query$i <- seq_len(nrow(query))
  geocoded <- .mapply(query, MoreArgs = options, FUN = structured_impl)
  as_sf(rbind_list(fit_original(geocoded[gids])))
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
    zoom = env$zoom,
    dedupe = env$dedupe,
    include = env$include,
    exclude = env$exclude
  )
}


is_komoot <- function(url) {
  grepl("photon.komoot.io", url, fixed = TRUE)
}


#' @rdname structured
#' @export
has_structured_support <- function() {
  url <- get_photon_url()
  can_access_photon(url, "structured")
}
