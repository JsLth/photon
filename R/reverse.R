reverse <- function(.data, radius = NULL, limit = 3, lang = NULL, osm_tag = NULL) {

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
  httr2::resp_body_json(resp, simplifyVector = TRUE)
}
