#' Download search index
#' @description
#' Finds and downloads the OpenSearch index database necessary to set up
#' Photon locally.
#'
#' \code{list_regions} returns an overview of regions and countries that
#' are valid to pass to the \code{region} argument.
#'
#' @param region Character string that identifies a region or country. An
#' extract for this region will be downloaded. If \code{"planet"}, downloads
#' a global extract (see note). Run \code{list_regions()} to get an overview
#' of available regions. You can specify countries using any code that can
#' be translated by \code{\link[countrycode]{countrycode}}.
#' @param path Path to a directory where the identified file should be stored.
#' Defaults to \code{tempdir()}.
#' @param version Photon version that the database should be used with. Defaults
#' to the latest version known to the package (`r get_latest_photon()`). Can
#' also be \code{"master"}, which is probably based on the master branch of
#' photon.
#' @param json Extracts come in two forms: JSON dumps and pre-build databases.
#' Pre-built databases are more convenient but less flexible and are not available
#' for all regions. If you wish or need to build your own database, set
#' \code{json = TRUE} and use the \code{$import()} method (see
#' \code{\link{photon_local}}).
#' @param only_url If \code{TRUE}, performs a download. Otherwise,
#' only returns a link to the file.
#' @param quiet If \code{TRUE}, suppresses all informative messages.
#' @param country Deprecated since photon 1.0.0. Use \code{region} instead.
#' @returns If \code{only_url = FALSE}, returns the local path to the downloaded
#' file. Otherwise, returns the URL to the remote file.
#'
#' @section Limitations:
#' The index download depends on a public repository
#' (\url{https://download1.graphhopper.com/public/}). This repository only
#' hosts search indices for the latest stable and experimental versions and
#' is thus not suitable for reproducibility. If you wish to make a project
#' reproducible, consider storing the search index somewhere persistent.
#' Photon is generally not backwards-compatible and newer versions of Photon
#' are not guaranteed to work with older search indices (based on personal
#' experience).
#'
#' Additionally, this function can only download pre-built search indices
#' from region extracts. If you need a more fine-grained scope or a combination
#' of multiple countries, you need to build your own search index. See
#' \code{vignette("nominatim-import", package = "photon")}.
#'
#'
#' @note
#' Depending on the region, search index databases tend to be very large.
#' The global search index is about 75 GB of size (10/2024). Keep that in mind
#' when running this function.
#'
#' @export
#'
#' @examplesIf getFromNamespace("is_online", "photon")("graphhopper.com") && getFromNamespace("photon_run_examples", "photon")()
#' # check available regions in Europe first
#' list_regions("europe")
#'
#' # download the latest database of Andorra
#' download_database("Andorra")
#'
#' # if you need to build your own search index, you can download a JSON dump
#' # this might also be necessary if no pre-built database dump exists
#' download_database("Andorra", json = TRUE)
#'
#' # get the latest global coverage
#' # NOTE: the file to be downloaded is several tens of gigabytes of size!
#' \dontrun{
#' download_database("planet")}
download_database <- function(region,
                              path = tempdir(),
                              version = get_latest_photon(),
                              json = FALSE,
                              only_url = FALSE,
                              quiet = FALSE,
                              country = NULL) {
  assert_vector(region, "character", size = 1, null = TRUE)
  deprecated(country, "1.0.0", "Use argument `region` instead.")

  req <- httr2::request("https://download1.graphhopper.com/public/")
  is_planet <- identical(region, "planet")
  url_region <- "planet"

  if (!is_planet) {
    region_long <- region
    country <- try_iso2(region)
    converted <- !identical(country, region)
    region <- country
    html <- rvest::read_html(req$url)
    regions <- rvest::html_table(html)[[1]]

    has_region <- FALSE
    if (!converted) {
      region <- gsub(" ", "-", tolower(region))
      has_region <- region == tolower(regions$Region)
      has_country <- has_region

      if (!any(has_region)) {
        ph_stop(
          c(
            "{.val {region}} is neither a country name nor a region name.",
            "i" = "Run `list_regions()` for a list of valid countries and regions."
          ),
          class = "country_invalid"
        )
      }
    } else {
      has_country <- grepl(region, regions$Countries, ignore.case = TRUE)
    }

    has_dump <- "\u2713" %in% regions[has_country, ]$`DB dump`
    if (!json && !has_dump) {
      json_dump_error(region_long) # nocov
    }

    url_region <- tolower(regions[has_country, "Region"])
    req <- httr2::req_url_path_append(req, url_region)

    if (!any(has_region)) {
      html <- rvest::read_html(req$url)
      regions <- rvest::html_table(html)[[1]]
      has_country <- grepl(region, regions$Countries, ignore.case = TRUE)

      has_dump <- "\u2713" %in% regions[has_country, ]$`DB dump`
      if (!json && !has_dump) {
        json_dump_error(region_long) # nocov
      }

      url_region <- tolower(regions[has_country, "Region"])
      req <- httr2::req_url_path_append(req, url_region)
    }
  }

  dump_name <- sprintf(
    "photon-%s-%s-%s-latest.%s",
    ifelse(json, "dump", "db"),
    url_region,
    substr(version, 1, 3),
    ifelse(json, "jsonl.zst", "tar.bz2")
  )
  req <- httr2::req_url_path_append(req, dump_name)
  path <- file.path(path, dump_name)

  if (only_url) return(req$url)
  req <- httr2::req_retry(req, max_tries = getOption("photon_max_tries", 3))

  if (globally_enabled("photon_movers")) {
    req <- httr2::req_progress(req)
  }

  if (!quiet) {
    cli::cli_progress_step(
      msg = "Fetching search index for {.field {region_long}}",
      msg_done = "Successfully downloaded search index.",
      msg_failed = "Failed to download search index."
    )
  }

  httr2::req_perform(req, path = path)
  normalizePath(path, "/")
}


#' @rdname download_database
#' @export
list_regions <- function(region = NULL) {
  base_url <- "https://download1.graphhopper.com/public/"

  if (!is.null(region)) {
    region <- gsub(" ", "-", tolower(region))
    base_url <- paste0(base_url, "/", region)
  }

  html <- rvest::read_html(base_url)
  regions <- rvest::html_table(html)[[1]]
  names(regions) <- c("region", "has_db_dump", "countries")
  regions$has_db_dump <- regions$has_db_dump == "\u2713"
  countries <- strsplit(regions$countries, ", ")
  countries <- vapply(countries, function(x) {
    cnames <- countrycode::countrycode(
      x,
      "iso2c",
      "country.name",
      warn = FALSE
    )
    cnames[is.na(cnames)] <- "Kosovo"
    paste(cnames, collapse = ", ")
  }, FUN.VALUE = character(1))
  regions$countries <- countries
  regions
}


try_iso2 <- function(country) {
  if (!is.character(country) && !is.numeric(country)) return(country)
  cc <- countrycode::countryname(country, destination = "iso2c", warn = FALSE)
  cc[is.na(cc)] <- country[is.na(cc)]
  cc
}


json_dump_error <- function(region) { # nocov start
  ph_stop(
    c(
      "Database dumps are not available for {.val {region}}.",
      "i" = "You need to set `json = TRUE` and build your own database from a JSON dump."
    ),
    class = "json_dump_error"
  )
} # nocov end
