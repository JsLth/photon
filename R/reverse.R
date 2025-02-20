#' Reverse geocoding
#' @description
#' Reverse geocode a set of points to retrieve their corresponding place names.
#' To geocode a place name or an address, see \link[=geocode]{unstructured}
#' or \link[=structured]{structured} geocoding.
#'
#' @param .data A dataframe or list with names \code{lon} and \code{lat}, or
#' an \code{sfc} or \code{sf} object containing point geometries.
#' @param radius Numeric specifying the range around the points in \code{.data}
#' that is used for searching.
#' @param distance_sort If \code{TRUE}, sorts the reverse geocoding results
#' based on the distance to the input point. Defaults to \code{TRUE}.
#' @inheritParams geocode
#' @inherit geocode details
#' @inherit geocode return
#'
#' @export
#'
#' @examples
#' \donttest{# an instance must be mounted first
#' photon <- new_photon()
#'
#' # works with sf objects
#' sf_data <- sf::st_sfc(sf::st_point(c(8, 52)), sf::st_point(c(7, 52)))
#' reverse(sf_data)
#'
#' # ... but also with simple dataframes
#' df_data <- data.frame(lon = c(8, 7), lat = c(52, 52))
#' reverse(df_data)
#'
#' # limit search radius to 10m
#' reverse(df_data, radius = 10)}
reverse <- function(.data,
                    radius = NULL,
                    limit = 1,
                    lang = "en",
                    osm_tag = NULL,
                    layer = NULL,
                    locbias = NULL,
                    locbias_scale = NULL,
                    zoom = NULL,
                    distance_sort = TRUE,
                    progress = interactive()) {
  assert_vector(radius, "numeric", null = TRUE)
  assert_vector(limit, "numeric", size = 1, null = TRUE)
  assert_vector(lang, "character", size = 1)
  assert_vector(osm_tag, "character", null = TRUE)
  assert_vector(layer, "character", null = TRUE)
  assert_vector(locbias_scale, "numeric", size = 1, null = TRUE)
  assert_vector(zoom, "numeric", size = 1, null = TRUE)
  assert_range(locbias_scale, min = 0, max = 1, than = FALSE)
  assert_range(radius, 0, 5000)
  assert_flag(progress)
  progress <- progress && globally_enabled("photon_movers")

  query <- format_points(.data)
  gids <- group_id(query)
  options <- list(env = environment())

  if (progress) {
    cli::cli_progress_bar(name = "Geocoding", total = length(gids))
  }

  query$i <- seq_len(nrow(query))
  geocoded <- .mapply(query, MoreArgs = options, FUN = reverse_impl)
  as_sf(rbind_list(fit_original(geocoded[gids])))
}

reverse_impl <- function(i, ..., env) {
  if (env$progress) cli::cli_progress_update(.envir = env)
  res <- query_photon(
    endpoint = "reverse",
    ...,
    radius = env$radius,
    limit = env$limit,
    lang = env$lang,
    osm_tag = env$osm_tag,
    layer = env$layer,
    lon = env$locbias$lon,
    lat = env$locbias$lat,
    location_bias_scale = env$locbias_scale,
    zoom = env$zoom
  )
}


format_points <- function(.data) {
  if (inherits(.data, c("sf", "sfc"))) {
    check_geometry(.data, type = "POINT")
    .data <- sf::st_coordinates(.data)
    .data <- data.frame(lon = .data[, "X"], lat = .data[, "Y"])
  } else {
    assert_class(.data, c("data.frame", "list"))
    assert_named(.data, c("lon", "lat"), all = TRUE)
    .data <- as.data.frame(.data)
  }

  .data
}


check_geometry <- function(x, type = "POINT") {
  cond <- all(sf::st_is(x, type))
  if (!cond) {
    var <- deparse(substitute(x))
    geom <- sf::st_geometry_type(x, by_geometry = FALSE)
    ph_stop(
      "{.code {var}} must consist of {type}s only, got {geom} instead.",
      class = "check_geometry"
    )
  }
}
