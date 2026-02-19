query_photon <- function(endpoint, ..., geojson = TRUE) {
  args <- drop_null(drop_na(list(...)))
  req <- httr2::request(get_photon_url())
  req <- httr2::req_template(req, "GET {endpoint}")
  req <- do.call(
    httr2::req_url_query,
    c(list(.req = req, .multi = "explode"), args)
  )
  req <- throttle(req)
  req <- httr2::req_retry(req, max_tries = getOption("photon_max_tries", 3))
  req <- httr2::req_error(req, body = function(resp) {
    ctype <- httr2::resp_content_type(resp)
    if (grepl("json", ctype, fixed = TRUE)) {
      httr2::resp_body_json(resp)[[1]][[1]]$message
    }
  })

  if (globally_enabled("photon_debug")) {
    cli::cli_inform("GET {req$url}") # nocov
  }

  resp <- httr2::req_perform(req)

  if (geojson) {
    resp <- httr2::resp_body_string(resp, encoding = "UTF-8")
    sf::st_read(resp, as_tibble = TRUE, quiet = TRUE, drivers = "geojson")
  } else {
    httr2::resp_body_json(resp)
  }
}


throttle <- function(req) {
  rate <- getOption("photon_throttle")
  if (is_komoot(req$url) || !is.null(rate)) {
    dflt <- 60 / 60
    req <- httr2::req_throttle(req, rate = rate %||% dflt)
  }
  req
}
