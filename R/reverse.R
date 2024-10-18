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
                    limit = 3,
                    lang = "en",
                    osm_tag = NULL,
                    layer = NULL,
                    distance_sort = TRUE,
                    progress = interactive()) {
  assert_vector(radius, "double", null = TRUE)
  assert_vector(limit, "double", null = TRUE)
  assert_vector(lang, "character", null = TRUE)
  assert_vector(osm_tag, "character", null = TRUE)
  assert_length(limit, null = TRUE)
  assert_range(radius, 0, 5000)
  assert_true_or_false(progress)
  progress <- progress && globally_enabled("photon_movers")

  .data <- format_points(.data)

  if (progress) {
    cli::cli_progress_bar(name = "Geocoding", total = nrow(.data))
    env <- environment()
  }

  options <- list(env = environment())
  .data$i <- seq_len(nrow(.data))
  geocoded <- .mapply(.data, MoreArgs = options, FUN = reverse_impl)
  as_sf(rbind_list(geocoded))
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
    layer = env$layer
  )
  cbind(idx = rep(i, nrow(res)), res)
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
