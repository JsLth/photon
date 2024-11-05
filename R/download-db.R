#' Download search index
#' @description
#' Finds and downloads the Elasticsearch index database necessary to set up
#' Photon locally.
#'
#' @param path Path to a directory where the identified file should be stored.
#' @param country Character string that can be identified by
#' \code{\link[countrycode]{countryname}} as a country. An extract for this
#' country will be downloaded. If \code{"planet"}, downloads a global search
#' index.
#' @param date Character string or date-time object used to specify the creation
#' date of the search index. If \code{"latest"}, will download the file tagged
#' with "latest". If a character string, the value should be parseable by
#' \code{\link{as.POSIXct}}. If \code{exact = FALSE}, the input value is
#' compared to all available dates and the closest date will be selected.
#' Otherwise, a file will be selected that exactly matches the input to
#' \code{date}.
#' @param exact If \code{TRUE}, exactly matches the \code{date}. Otherwise,
#' selects the date with lowest difference to the \code{date} parameter.
#' @param section Subdirectory of the download server from which to select a
#' search index. If \code{"experimental"}, selects a dump made for the master
#' version of photon. If \code{"archived"}, selects a dump made for an older
#' version of photon. If \code{NULL}, selects a dump made for the current
#' release. Defaults to \code{NULL}.
#' @param only_url If \code{TRUE}, performs a download. Otherwise,
#' only returns a link to the file.
#' @param quiet If \code{TRUE}, suppresses all informative messages.
#' @returns If \code{only_url = FALSE}, returns the local path to the downloaded
#' file. Otherwise, returns the URL to the remote file.
#'
#' @note
#' Depending on the country, search index databases tend to be very large.
#' The global search index is about 75 GB of size (10/2024). Keep that in mind
#' when running this function.
#'
#' @export
#'
#' @examples
#' \donttest{# download the latest extract of Monaco
#' download_searchindex(path = tempdir())
#'
#' # download the latest extract of American Samoa
#' download_searchindex(path = tempdir(), country = "Samoa")
#'
#' # download an extract from a month ago
#' download_searchindex(path = tempdir(), country = "Monaco", date = Sys.time() - 2629800)
#'
#' # if possible, download an extract from today
#' try(download_searchindex(path = tempdir(), country = "Monaco", date = Sys.Date(), exact = TRUE))}
#'
#' # get the latest global coverage
#' # NOTE: the file to be downloaded is several tens of gigabytes of size!
#' \dontrun{
#' download_searchindex(path = tempdir(), country = "planet")}
download_searchindex <- function(path = ".",
                                 country = "Monaco",
                                 date = "latest",
                                 exact = FALSE,
                                 section = NULL,
                                 only_url = FALSE,
                                 quiet = FALSE) {
  assert_length(country, 1, null = TRUE)
  assert_length(date, 1, null = TRUE)
  assert_length(exact, 1)
  assert_vector(country, "character")
  assert_flag(exact)
  is_planet <- identical(country, "planet")
  req <- httr2::request("https://download1.graphhopper.com/public/")
  req <- httr2::req_url_path_append(req, switch(
    section %||% "",
    experimental = "experimental",
    archived = "archived/0.3",
    ""
  ))

  if (!is_planet) {
    country <- tolower(countrycode::countryname(
      country,
      destination = "iso2c",
      warn = FALSE
    ))

    if (is.na(country)) {
      ph_stop(paste(
        "{.code country} is not a valid country name. See",
        "{.code ?countrycode::countryname()} for details."
      ), class = "country_invalid")
    }

    req <- httr2::req_url_path_append(req, "extracts", "by-country-code", country)
  }

  date_format <- "%y%m%d"
  if (!identical(date, "latest")) {
    date <- as.POSIXct(date)
    html <- httr2::resp_body_string(httr2::req_perform(req))
    html <- strsplit(html, "\n")[[1]]
    all_dates <- regex_match(
      html,
      sprintf(
        "photon-db%s-([0-9]+)\\.tar\\.bz2</a>",
        if (!is_planet) paste0("-", country) else ""
      ),
      i = 2
    )
    all_dates <- as.POSIXct(drop_na(all_dates), format = date_format, tz = "UTC")

    if (exact) {
      if (!date %in% all_dates) {
        ph_stop(c(
          "!" = "Specified {.code date} does not match any available dates.",
          "i" = "Consider setting {.code exact = FALSE}."
        ), class = "no_index_match")
      }

    } else {
      diff <- date - all_dates
      date <- all_dates[diff == min(diff)]
    }

    date <- format(as.POSIXct(date), date_format)
  }

  if (is_planet) {
    file <- sprintf("photon-db-%s.tar.bz2", date)
  } else {
    file <- sprintf("photon-db-%s-%s.tar.bz2", country, date)
  }

  path <- file.path(path, file)
  req <- httr2::req_url_path_append(req, file)
  if (only_url) return(req$url)
  req <- httr2::req_retry(req, max_tries = getOption("photon_max_tries", 3))

  if (globally_enabled("photon_movers")) {
    req <- httr2::req_progress(req)
  }

  if (!quiet) {
    date_fmt <- ifelse(
      identical(date, "latest"),
      date,
      format(as.POSIXct(date, format = date_format), "%Y-%m-%d")
    )
    if (is_planet) {
      country <- "Planet" # nocov
    } else {
      country <- countrycode::countrycode(country, "iso2c", "country.name")
    }
    cli::cli_progress_step(
      msg = "Fetching search index for {.field {country}}, created on {.field {date_fmt}}",
      msg_done = "Successfully downloaded search index.",
      msg_failed = "Failed to download search index."
    )
  }


  httr2::req_perform(req, path = path)
  normalizePath(path, "/")
}
