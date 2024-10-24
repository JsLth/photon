photon_env <- new.env(parent = emptyenv())

#' Photon utilities
#' @description
#' Utilities to manage photon instances. These functions operate on mounted
#' photon instances which can be initialized using \code{\link{new_photon}}.
#'
#' \itemize{
#'  \item{\code{get_instance()} retrieves the active photon instance.}
#'  \item{\code{get_photon_url()} retrieves the photon URL to send requests.}
#' }
#'
#' @returns \code{get_instance} returns a R6 object of class \code{photon}.
#' \code{get_photon_url()} returns a URL string.
#'
#' @export
#'
#' @examples
#' # make a new photon instance
#' new_photon()
#'
#' # retrieve it from the cache
#' get_instance()
#'
#' # get the server url
#' get_photon_url()
get_instance <- function() {
  instance <- get0("instance", envir = photon_env)

  if (is.null(instance)) {
    ph_stop(c(
      "x" = "No photon instance found.",
      "i" = "You can start a new instance using {.code new_photon()}."
    ), class = "instance_missing")
  }

  instance
}

#' @rdname get_instance
#' @export
get_photon_url <- function() {
  instance <- get_instance()
  instance$get_url()
}

clear_cache <- function() {
  rm(list = ls(envir = photon_env), envir = photon_env)
}

#' Initialize a photon instance
#' @description
#' Initialize a photon instance by creating a new photon object. This object
#' is stored in the R session and can be used to perform geocoding requests.
#'
#' Instances can either local or remote. Remote instances require nothing more
#' than a URL that geocoding requests are sent to. Local instances require the
#' setup of the photon executable, an Elasticsearch index, and Java. See
#' \code{\link{photon_local}} for details.
#'
#' @param path Path to a directory where the photon executable and data
#' should be stored. Defaults to a directory "photon" in the current
#' working directory. If \code{NULL}, a remote instance is set up based on
#' the \code{url} parameter.
#' @param url URL of a photon server to connect to. If \code{NULL} and
#' \code{path} is also \code{NULL}, connects to the public API under
#' \url{photon.komoot.io}.
#' @param ... Arguments passed to \code{\link[=photon_local]{photon_local$new()}}.
#'
#' @returns An R6 object of class \code{photon}.
#'
#' @export
#'
#' @examples
#' # connect to public API
#' photon <- new_photon()
#'
#' # connect to arbitrary server
#' photon <- new_photon(url = "photonserver.org")
#'
#' \dontrun{
#' # set up a local instance
#' photon <- new_photon(path = tempdir())}
new_photon <- function(path = NULL, url = NULL, ...) {
  if (is.null(path) && is.null(url)) {
    photon_remote$new(url = "https://photon.komoot.io/")
  } else if (is.null(path)) {
    photon_remote$new(url = url)
  } else if (is.null(url)) {
    photon_local$new(path = path, ...)
  }
}


photon <- R6::R6Class(classname = "photon")


# Remote ----
photon_remote <- R6::R6Class(
  classname = "photon_remote",
  inherit = photon,
  public = list(
    ## public ----
    initialize = function(url) {
      assert_url(url)
      private$url <- url
      self$mount()
      invisible(self)
    },

    get_url = function() {
      private$url
    },

    mount = function() {
      assign("instance", self, envir = photon_env)
    }
  ),

  private = list(
    ## private ----
    url = NULL
  )
)


# Local ----
#' Local photon instance
#' @description
#' This R6 class is used to initialize and manage local photon instances.
#' It can download and setup the Java, the photon executable, and the necessary
#' Elasticsearch search index. It can start, stop, and query the status of the
#' photon instance. It is also the basis for geocoding requests at it is used
#' to retrieve the URL for geocoding.
#'
#' @section ElasticSearch:
#' The standard version of photon uses ElasticSearch indices to geocode.
#' These search indices can be self-provided by importing an existing
#' Nominatim database or they can be downloaded from the
#' \href{https://nominatim.org/2020/10/21/photon-country-extracts.html}{Photon download server}.
#' Use \code{nominatim = TRUE} to indicate that no ElasticSearch indices
#' should be downloaded.
#'
#'
#' @section OpenSearch:
#' To enable structured geocoding, the photon geocoder needs to be built to
#' support OpenSearch. Currently, this feature is only experimental and needs
#' to be manually built using gradle.
#' When using the OpenSearch version of photon, no pre-built ElasticSearch
#' indices can be used and the data must be directly imported from a
#' Nominatim database. Refer to the photon
#' \href{https://github.com/komoot/photon}{README} for details. These steps
#' cannot be done by \code{\{photon\}} and must be done before initializing
#' \code{photon_local}. If an OpenSearch jar is detected, the \code{nominatim}
#' parameter is forced to \code{TRUE}.
#'
#' @export
#' @import R6
#'
#' @examples
#' if (FALSE) {
#' dir <- file.path(tempdir(), "photon")
#'
#' # start a new instance using a Monaco extract
#' photon <- new_photon(path = dir, country = "Monaco")
#'
#' # start a new instance with an older photon version
#' photon <- new_photon(path = dir, photon_version = "0.4.1")
#'
#' # import a nominatim database using OpenSearch photon
#' # this example requires the OpenSearch version of photon and a running
#' # Nominatim server.
#' file.copy(
#'   "path/to/photon-opensearch-0.5.0.jar",
#'   file.path(dir, "photon-opensearch-0.5.0.jar")
#' )
#' photon <- new_photon(path = dir, nominatim = TRUE)
#' photon$start(photon_options = import_options(port = 29146, password = "pgpass"))
#' }
photon_local <- R6::R6Class(
  inherit = photon,
  classname = "photon_local",
  public = list(
    ## Public ----
    #' @field path Path to the directory where the photon instance is stored.
    path = NULL,

    #' @field proc \code{\link[processx]{process}} object that handles the
    #' external process running photon.
    proc = NULL,

    #' @description
    #' Initialize a local photon instance. If necessary, downloads the photon
    #' executable, the search index, and Java.
    #'
    #' @param path Path to a directory where the photon executable and data
    #' should be stored. Defaults to a directory "photon" in the current
    #' working directory.
    #' @param photon_version Version of photon to be used. A list of all
    #' releases can be found here: \url{https://github.com/komoot/photon/releases/}.
    #' @param country Character string that can be identified by
    #' \code{\link[countrycode]{countryname}} as a country. An extract for this
    #' country will be downloaded. If \code{NULL}, downloads a global search index.
    #' @param date Character string or date-time object used to specify the creation
    #' date of the search index. If \code{"latest"}, will download the file tagged
    #' with "latest". If a character string, the value should be parseable by
    #' \code{\link{as.POSIXct}}. If \code{exact = FALSE}, the input value is
    #' compared to all available dates and the closest date will be selected.
    #' Otherwise, a file will be selected that exactly matches the input to
    #' \code{date}.
    #' @param nominatim If \code{TRUE}, starts a Nominatim instance which does
    #' not use ElasticSearch indices. Use with care as Nominatim databases have
    #' to be manually set up and managed. If \code{TRUE} (default), downloads
    #' pre-built ElasticSearch indices from the photon download server.
    #' @param exact If \code{TRUE}, exactly matches the \code{date}. Otherwise,
    #' selects the date with lowest difference to the \code{date} parameter.
    #' @param quiet If \code{TRUE}, suppresses all informative messages.
    initialize = function(path = "./photon",
                          photon_version = NULL,
                          country = NULL,
                          date = "latest",
                          exact = FALSE,
                          nominatim = FALSE,
                          quiet = FALSE) {
      assert_true_or_false(quiet)
      check_jdk_version("11", quiet = quiet)

      path <- normalizePath(path, "/", mustWork = FALSE)
      if (!dir.exists(path)) {
        dir.create(path, recursive = TRUE) # nocov
      }

      # opensearch does not support elasticsearch
      if (has_opensearch_jar(path)) {
        cli::cli_warn("OpenSearch version detected. Setting {.code nominatim = TRUE}.")
        nominatim <- TRUE
      }
      # TODO: make sure the right jar is selected, not just the most convenient
      setup_photon_directory(
        path,
        photon_version,
        country = country,
        date = date,
        exact = exact,
        nominatim = nominatim,
        quiet = quiet
      )

      if (!nominatim) {
        meta <- show_metadata(path, quiet = quiet)
      } else {
        meta <- get_metadata(path)
        cli::cli_ul("Version: {meta$version}")
      }

      self$path <- path
      private$quiet <- quiet
      private$version <- meta$version
      private$country <- meta$country
      private$date <- meta$date
      private$nominatim <- nominatim
      self$mount()
      invisible(self)
    },

    #' @description
    #' Attach the object to the session. If mounted, all geocoding functions
    #' send their requests to the URL of this instance. Manually mounting
    #' is useful if you want to switch between multiple photon instances.
    mount = function() {
      assign("instance", self, envir = photon_env)
    },

    #' @description
    #' Retrieve metadata about the java and photon version used as well
    #' as the country and creation date of the Eleasticsearch search index.
    info = function() {
      info <- list(java = get_java_version(quiet = TRUE))
      c(info, get_metadata(self$path))
    },

    #' @description
    #' Kill the photon process and remove the directory. Useful to get rid
    #' of an instance entirely.
    purge = function() {
      if (interactive()) {
        cli::cli_inform(c("i" = paste( # nocov start
          "Purging an instance kills the photon process",
          "and removes the photon directory."
        )))
        yes_no("Continue?", no = cancel()) # nocov end
      }

      self$stop()
      rm <- unlink(self$path, recursive = TRUE, force = TRUE)

      if (identical(rm, 1L)) { # nocov start
        cli::cli_warn("Photon directory could not be removed.")
      } # nocov end

      invisible(NULL)
    },

    #' @description
    #' Import a Postgres Nominatim database to photon. Runs the photon jar
    #' file using the additional parameter \code{-nominatim-import}. Requires
    #' a running Nominatim database that can be connected to.
    #'
    #' @param host Postgres host of the database. Defaults to \code{"127.0.0.1"}.
    #' @param port Postgres port of the database. Defaults to \code{5432}.
    #' @param database Postgres database name. Defaults to \code{"nominatim"}.
    #' @param user Postgres database user. Defaults to \code{"nominatim"}.
    #' @param password Postgres database password. Defaults to \code{""}.
    #' @param structured If \code{TRUE}, enables structured query support when
    #' importing the database. This allows the usage of
    #' \code{\link{structured}}. Structured queries are only supported in the
    #' OpenSearch version of photon. See section "OpenSearch" above. Defaults
    #' to \code{FALSE}.
    #' @param update If \code{TRUE}, fetches updates from the Nominatim database,
    #' updating the search index without offering an API. If \code{FALSE},
    #' imports the database an deletes the previous index. Defaults to
    #' \code{FALSE}.
    #' @param enable_update_api If \code{TRUE}, enables an additional
    #' endpoint \code{/nominatim-update}, which allows updates from
    #' Nominatim databases.
    #' @param languages Character vector specifying the languages to import
    #' from the Nominatim databases. Defaults to English, French, German,
    #' and Italian.
    #' @param countries Character vector specifying the country codes to
    #' import from the Nominatim database. Defaults to all country codes.
    #' @param extra_tags Character vector specifying extra OSM tags to import
    #' from the Nominatim database. These tags are used to augment geocoding
    #' results. Defaults to \code{NULL}.
    #' @param json If \code{TRUE}, dumps the imported Nominatim database to
    #' a JSON file and returns the path to the output file. Defaults to
    #' \code{FALSE}.
    #' @param java_opts List of further flags passed on to the \code{java}
    #' command.
    #' @param photon_opts List of further flags passed on to the photon
    #' jar in the java command. See \code{\link{import_options}} for a helper
    #' function to import external Nominatim databases.
    import = function(host = "127.0.0.1",
                      port = 5432,
                      database = "nominatim",
                      user = "nominatim",
                      password = "",
                      structured = FALSE,
                      update = FALSE,
                      enable_update_api = FALSE,
                      languages = c("en", "fr", "de", "it"),
                      countries = NULL,
                      extra_tags = NULL,
                      json = FALSE,
                      java_opts = NULL,
                      photon_opts = NULL) {
      opts <- cmd_options(
        host = host,
        port = port,
        database = database,
        user = user,
        password = password,
        nominatim_update = update,
        enable_update_api = enable_update_api,
        languages = languages,
        country_codes = countries,
        extra_tags = extra_tags,
        json = json
      )

      run_photon(
        self, private,
        java_opts = java_opts,
        photon_opts = c(opts, photon_opts)
      )

      self$mount()
      invisible(self)
    },

    #' @description
    #' Start a local instance of the Photon geocoder. Runs the jar executable
    #' located in the instance directory.
    #'
    #' @param min_ram Initial RAM to be allocated to the Java process
    #' (\code{-Xms} flag).
    #' @param max_ram Maximum RAM to be allocated to the Java process
    #' (\code{-Xmx} flag)
    #' @param host Character string of the host name that the geocoder should
    #' be opened on.
    #' @param port Port that the geocoder should listen to.
    #' @param ssl If \code{TRUE}, uses \code{https}, otherwise \code{http}.
    #' Defaults to \code{FALSE}.
    #' @param java_opts List of further flags passed on to the \code{java}
    #' command.
    #' @param photon_opts List of further flags passed on to the photon
    #' jar in the java command. See \code{\link{import_options}} for a helper
    #' function to import external Nominatim databases.
    #'
    #' @details
    #' While there is a certain way to determine if a photon instance is
    #' ready, there is no clear way as of yet to determine if a photon setup
    #' has failed. Due to this, a failing setup is mostly indicated by the
    #' setup hanging after emitting a warning. In this case, the setup has to
    #' be interrupted manually.
    start = function(min_ram = 5,
                     max_ram = 10,
                     host = "0.0.0.0",
                     port = "2322",
                     ssl = FALSE,
                     java_opts = NULL,
                     photon_opts = NULL) {
      assert_vector(min_ram, "double")
      assert_vector(max_ram, "double")
      assert_vector(host, "character")
      assert_vector(java_opts, "character", null = TRUE)
      assert_vector(photon_opts, "character", null = TRUE)
      assert_true_or_false(ssl)

      jopts <- cmd_options(
        sprintf("-Xms%sg", min_ram),
        sprintf("-Xmx%sg", max_ram)
      )
      popts <- cmd_options(
        listen_ip = host,
        listen_port = port
      )

      self$proc <- run_photon(
        self, private,
        java_opts = java_opts,
        photon_opts = photon_opts
      )

      private$host <- host
      private$port <- port
      private$ssl <- ssl

      self$mount()
      invisible(self)
    },

    #' @description
    #' Kills the running photon process.
    stop = function() {
      stop_photon(self)
      invisible(self)
    },

    #' @description
    #' Checks whether the photon instance is running and ready. The difference
    #' to \code{$is_ready()} is that \code{$is_running()} checks specifically
    #' if the running photon instance is managed by a process from its own
    #' \code{photon} object. In other words, \code{$is_running()} returns
    #' \code{TRUE} if both \code{$proc$is_alive()} and \code{$is_ready()}
    #' return \code{TRUE}. This method is useful if you want to ensure that
    #' the \code{photon} object can control its photon server (mostly internal
    #' use).
    is_running = function() {
      photon_running(self)
    },

    #' @description
    #' Checks whether the photon instance is ready to take requests. This
    #' is the case if the photon server returns a HTTP 400 when sending a
    #' queryless request. This method is useful if you want to check whether
    #' you can send requests.
    is_ready = function() {
      photon_ready(self, private)
    },

    #' @description
    #' Constructs the URL that geocoding requests should be sent to.
    get_url = function() {
      host <- private$host
      port <- private$port

      if (is.null(host)) {
        ph_stop(c(
          "x" = "Photon server has not been started yet.",
          "i" = "Start it by calling {.code $start()}"
        ), class = "no_url_yet")
      }

      if (identical(host, "0.0.0.0")) host <- "localhost" # nocov
      ssl <- ifelse(isTRUE(private$ssl), "s", "")
      sprintf("http%s://%s:%s", ssl, host, port)
    }
  ),

  private = list(
    ## Private ----
    quiet = FALSE,
    version = NULL,
    host = NULL,
    port = NULL,
    ssl = NULL,
    country = NULL,
    date = NULL,
    nominatim = NULL,
    finalize = function() {
      self$stop() # nocov
    }
  )
)


# External ----
setup_photon_directory <- function(path,
                                  version,
                                  ...,
                                  nominatim = FALSE,
                                  quiet = FALSE) {
  files <- list.files(path, full.names = TRUE)
  if (!any(grepl("\\.jar$", files))) {
    download_photon(path = path, version = version, quiet = quiet)
  } else if (!quiet) {
    cli::cli_inform(c("i" = paste(
      "A photon executable already exists in the given path.",
      "Download will be skipped."
    )))
  }

  if (nominatim) {
    return()
  }

  if (!any(grepl("photon_data$", files))) {
    has_archive <- grepl("\\.bz2$", files)
    if (!any(has_archive)) {
      archive_path <- download_searchindex(path = path, ..., quiet = quiet)
    } else {
      archive_path <- files[has_archive] # nocov
    }
    on.exit(unlink(archive_path))
    untared <- utils::untar(archive_path, files = "photon_data", exdir = path)

    if (!identical(untared, 0L)) { # nocov start
      ph_stop("Failed to untar the Elasticsearch index.")
    } # nocov end

    store_searchindex_metadata(path, archive_path)
  } else if (!quiet) {
    cli::cli_inform(c("i" = paste(
      "A search index already exists at the given path.",
      "Download will be skipped"
    )))
  }
}


store_searchindex_metadata <- function(path, archive_path) {
  meta <- utils::strcapture(
    pattern = "photon-db-?([a-z]{2})?-([0-9]+|latest)\\.tar\\.bz2",
    x = basename(archive_path),
    proto = data.frame(country = character(), date = character())
  )
  meta$date <- ifelse(
    identical(meta$date, "latest"),
    meta$date,
    as.POSIXct(meta$date, format = "%y%m%d")
  )
  meta$country <- ifelse(
    nzchar(meta$country),
    countrycode::countrycode(meta$country, "iso2c", "country.name"),
    "global"
  )
  saveRDS(meta, file.path(path, "photon_data", "rmeta.rds"))
}


get_metadata <- function(path) {
  meta_path <- file.path(path, "photon_data", "rmeta.rds")

  if (!file.exists(meta_path)) {
    # if photon_data has been created outside of {photon}, metadata cannot be retrieved
    meta <- list(country = "Unknown", meta = "Unknown") # nocov
  } else {
    meta <- readRDS(meta_path)
  }

  as.list(c(version = get_photon_version(path), meta))
}


show_metadata <- function(path, quiet = FALSE) {
  meta <- get_metadata(path)

  if (!quiet) {
    cli::cli_ul(c(
      sprintf("Version: %s", meta$version),
      sprintf("Coverage: %s", meta$country),
      sprintf("Time: %s", meta$date)
    ))
  }

  meta
}


get_photon_version <- function(path) {
  file <- list.files(path, pattern = "photon-.+\\.jar$")[[1]]
  regex_match(file, "photon-([a-z]+-)?(.+)\\.jar", i = 3)
}

#' @export
print.photon <- function(x, ...) {
  type <- ifelse(inherits(x, "photon_remote"), "remote", "local")

  info <- switch(
    type,
    remote = c(
      sprintf("Type   : %s", type),
      sprintf("Server : %s", x$get_url())
    ),
    local = {
      info <- x$info()
      info <- c(
        sprintf("Type     : %s", type),
        sprintf("Version  : %s", info$photon),
        sprintf("Coverage : %s", info$country),
        sprintf("Time     : %s", info$date)
      )
    }
  )

  info <- gsub("\\s", "\u00a0", info)
  names(info) <- rep(" ", length(info))
  cli::cli_text(cli::col_blue("<photon>"))
  cli::cli_bullets(info)
  invisible(x)
}


has_opensearch_jar <- function(path) {
  files <- list.files(path)
  any(grepl("photon-opensearch-.+\\.jar", files))
}
