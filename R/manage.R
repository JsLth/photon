photon_env <- new.env(parent = emptyenv())

photon_cache <- function() {
  get("photon_env", envir = asNamespace("photon"))
}

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
  instance <- get0("instance", envir = photon_cache())

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
  rm(list = ls(envir = photon_cache()), envir = photon_cache())
}

#' Initialize a photon instance
#' @description
#' Initialize a photon instance by creating a new photon object. This object
#' is stored in the R session and can be used to perform geocoding requests.
#'
#' Instances can either local or remote. Remote instances require nothing more
#' than a URL that geocoding requests are sent to. Local instances require the
#' setup of the photon executable, a search index, and Java. See
#' \code{\link{photon_local}} for details.
#'
#' @param path Path to a directory where the photon executable and data
#' should be stored. Defaults to a directory "photon" in the current
#' working directory. If \code{NULL}, a remote instance is set up based on
#' the \code{url} parameter.
#' @param url URL of a photon server to connect to. If \code{NULL} and
#' \code{path} is also \code{NULL}, connects to the public API under
#' \url{photon.komoot.io}.
#' @param photon_version Version of photon to be used. A list of all
#' releases can be found here: \url{https://github.com/komoot/photon/releases/}.
#' Ignored if \code{jar} is given. If \code{NULL}, uses the latest known
#' version.
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
#' @param opensearch If \code{TRUE}, looks for an OpenSearch version of
#' photon in the specified path. Opensearch-based photon supports structured
#' geocoding queries but has to be built manually using gradle. Hence,
#' it cannot be downloaded directly. If no OpenSearch executable is found
#' in the search path, then this parameter is set to \code{FALSE}. Defaults
#' to \code{FALSE}. See \code{vignette("nominatim-import", package = "photon")}
#' for details.
#' @param exact If \code{TRUE}, exactly matches the \code{date}. Otherwise,
#' selects the date with lowest difference to the \code{date} parameter.
#' @param overwrite If \code{TRUE}, overwrites existing jar files and
#' search indices when initializing a new instance. Defaults to
#' \code{FALSE}.
#' @param quiet If \code{TRUE}, suppresses all informative messages.
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
#' # set up a local instance in the current working directory
#' photon <- new_photon("photon", country = "Ireland")}
new_photon <- function(path = NULL,
                       url = NULL,
                       photon_version = NULL,
                       country = NULL,
                       date = "latest",
                       exact = FALSE,
                       opensearch = FALSE,
                       overwrite = FALSE,
                       quiet = FALSE) {
  if (is.null(path) && is.null(url)) {
    photon_remote$new(url = "https://photon.komoot.io/")
  } else if (is.null(path)) {
    photon_remote$new(url = url)
  } else if (is.null(url)) {
    photon_local$new(
      path = path,
      photon_version = photon_version,
      country = country,
      date = date,
      exact = exact,
      opensearch = opensearch,
      overwrite = overwrite,
      quiet = quiet
    )
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
      assign("instance", self, envir = photon_cache())
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
#' should be downloaded. See
#' \code{vignette("nominatim-import", package = "photon")} for details on how
#' to import from Nominatim.
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
#' photon$start(photon_options = cmd_options(port = 29146, password = "pgpass"))
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
    #' Ignored if \code{jar} is given. If \code{NULL}, uses the latest known
    #' version.
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
    #' @param opensearch If \code{TRUE}, looks for an OpenSearch version of
    #' photon in the specified path. Opensearch-based photon supports structured
    #' geocoding queries but has to be built manually using gradle. Hence,
    #' it cannot be downloaded directly. If no OpenSearch executable is found
    #' in the search path, then this parameter is set to \code{FALSE}. Defaults
    #' to \code{FALSE}.
    #' @param exact If \code{TRUE}, exactly matches the \code{date}. Otherwise,
    #' selects the date with lowest difference to the \code{date} parameter.
    #' @param overwrite If \code{TRUE}, overwrites existing jar files and
    #' search indices when initializing a new instance. Defaults to
    #' \code{FALSE}.
    #' @param quiet If \code{TRUE}, suppresses all informative messages.
    initialize = function(path = "./photon",
                          photon_version = NULL,
                          country = NULL,
                          date = "latest",
                          exact = FALSE,
                          opensearch = FALSE,
                          overwrite = FALSE,
                          quiet = FALSE) {
      assert_flag(quiet)
      assert_flag(opensearch)
      check_jdk_version("11", quiet = quiet)
      photon_version <- photon_version %||% get_latest_photon()

      path <- normalizePath(path, "/", mustWork = FALSE)
      if (!dir.exists(path)) {
        dir.create(path, recursive = TRUE) # nocov
      }

      setup_photon_directory(
        path,
        photon_version,
        country = country,
        date = date,
        exact = exact,
        opensearch = opensearch,
        overwrite = overwrite,
        quiet = quiet
      )

      self$path <- path
      private$quiet <- quiet
      private$version <- photon_version
      private$opensearch <- opensearch

      meta <- private$get_metadata(quiet = quiet)
      private$country <- meta$country
      private$date <- meta$date
      self$mount()
      invisible(self)
    },

    #' @description
    #' Attach the object to the session. If mounted, all geocoding functions
    #' send their requests to the URL of this instance. Manually mounting
    #' is useful if you want to switch between multiple photon instances.
    mount = function() {
      assign("instance", self, envir = photon_cache())
    },

    #' @description
    #' Retrieve metadata about the java and photon version used as well
    #' as the country and creation date of the Eleasticsearch search index.
    info = function() {
      info <- list(java = get_java_version(quiet = TRUE))
      c(info, private$get_metadata(quiet = TRUE))
    },

    #' @description
    #' Kill the photon process and remove the directory. Useful to get rid
    #' of an instance entirely.
    #' @param ask If \code{TRUE}, asks for confirmation before purging the
    #' instance.
    purge = function(ask = TRUE) {
      if (interactive() || !ask) {
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
    #' @param timeout Time in seconds before the java process aborts. Defaults
    #' to 60 seconds.
    #' @param java_opts List of further flags passed on to the \code{java}
    #' command.
    #' @param photon_opts List of further flags passed on to the photon
    #' jar in the java command. See \code{\link{cmd_options}} for a helper
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
                      timeout = 60,
                      java_opts = NULL,
                      photon_opts = NULL) {
      assert_vector(host, "character")
      assert_vector(database, "character")
      assert_vector(user, "character")
      assert_vector(password, "character")
      assert_vector(languages, "character", null = TRUE)
      assert_vector(countries, "character", null = TRUE)
      assert_vector(extra_tags, "character", null = TRUE)
      assert_vector(timeout, "double")
      assert_vector(java_opts, "character", null = TRUE)
      assert_vector(photon_opts, "character", null = TRUE)
      assert_flag(structured)
      assert_flag(update)
      assert_flag(enable_update_api)
      assert_flag(json)

      if (structured && !private$opensearch) {
        cli::cli_warn(paste(
          "Structured queries are only supported for OpenSearch photon.",
          "Setting {.code structured = FALSE}."
        ))
        structured <- FALSE
      }

      popts <- cmd_options(
        nominatim_import = TRUE,
        host = host,
        port = port,
        database = database,
        user = user,
        password = password,
        structured = structured,
        nominatim_update = update,
        enable_update_api = enable_update_api,
        languages = languages,
        country_codes = countries,
        extra_tags = extra_tags,
        json = json
      )

      run_photon(
        self, private,
        mode = "import",
        java_opts = java_opts,
        photon_opts = c(popts, photon_opts)
      )

      self$mount()
      invisible(self)
    },

    #' @description
    #' Start a local instance of the Photon geocoder. Runs the jar executable
    #' located in the instance directory.
    #'
    #' @param host Character string of the host name that the geocoder should
    #' be opened on.
    #' @param port Port that the geocoder should listen to.
    #' @param ssl If \code{TRUE}, uses \code{https}, otherwise \code{http}.
    #' Defaults to \code{FALSE}.
    #' @param timeout Time in seconds before the java process aborts. Defaults
    #' to 60 seconds.
    #' @param java_opts List of further flags passed on to the \code{java}
    #' command.
    #' @param photon_opts List of further flags passed on to the photon
    #' jar in the java command. See \code{\link{cmd_options}} for a helper
    #' function to import external Nominatim databases.
    #'
    #' @details
    #' While there is a certain way to determine if a photon instance is
    #' ready, there is no clear way as of yet to determine if a photon setup
    #' has failed. Due to this, a failing setup is mostly indicated by the
    #' setup hanging after emitting a warning. In this case, the setup has to
    #' be interrupted manually.
    start = function(host = "0.0.0.0",
                     port = "2322",
                     ssl = FALSE,
                     timeout = 60,
                     java_opts = NULL,
                     photon_opts = NULL) {
      assert_vector(host, "character")
      assert_vector(java_opts, "character", null = TRUE)
      assert_vector(photon_opts, "character", null = TRUE)
      assert_flag(ssl)

      private$host <- host
      private$port <- port
      private$ssl <- ssl

      popts <- cmd_options(listen_ip = host, listen_port = port)
      self$proc <- run_photon(
        self, private,
        mode = "start",
        java_opts = java_opts,
        photon_opts = c(popts, photon_opts)
      )

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
    opensearch = NULL,
    finalize = function() {
      self$stop() # nocov
    },
    get_metadata = function(quiet = TRUE) {
      meta_path <- file.path(self$path, "photon_data", "rmeta.rds")

      if (!file.exists(meta_path)) {
        # if photon_data has been created outside of {photon}, metadata cannot be retrieved
        meta <- list(country = NULL, date = NULL) # nocov
      } else {
        meta <- readRDS(meta_path)
      }

      meta <- as.list(c(
        version = private$version,
        opensearch = private$opensearch,
        meta
      ))

      if (!quiet) {
        cli::cli_ul(c(
          sprintf("Version: %s", meta$version),
          sprintf("Coverage: %s", meta$country),
          sprintf("Time: %s", meta$date)
        ))
      }

      meta
    }
  )
)


# External ----
setup_photon_directory <- function(path,
                                   version,
                                   country = NULL,
                                   date = NULL,
                                   exact = FALSE,
                                   opensearch = FALSE,
                                   overwrite,
                                   quiet = FALSE) {
  jar <- construct_jar(version, opensearch)

  files <- list.files(path, full.names = TRUE)
  if (!jar %in% basename(files) || overwrite) {
    if (opensearch) {
      link <- cli::style_hyperlink("README", "https://github.com/komoot/photon")
      msg <- c(
        "The OpenSearch version of photon has to be built manually.",
        "i" = "Refer to the photon {link} for details."
      )
      ph_stop(msg)
    }

    download_photon(path = path, version = version, quiet = quiet)
  } else if (!quiet) {
    cli::cli_inform(c("i" = paste(
      "A photon executable already exists in the given path.",
      "Download will be skipped."
    )))
  }

  if (opensearch) {
    if (!is.null(country)) {
      cli::cli_inform(c(
        "i" = "OpenSearch does not support ElasticSearch indices. Skipping."
      ))
    }
    return()
  }

  if ((!any(grepl("photon_data$", files)) || overwrite) && !is.null(country)) {
    has_archive <- grepl("\\.bz2$", files)
    if (!any(has_archive)) {
      archive_path <- download_searchindex(
        path = path,
        country = country,
        date = date,
        exact = exact,
        quiet = quiet
      )
    } else {
      archive_path <- files[has_archive] # nocov
    }
    on.exit(unlink(archive_path))
    untared <- utils::untar(archive_path, files = "photon_data", exdir = path)

    if (!identical(untared, 0L)) { # nocov start
      ph_stop("Failed to untar the Elasticsearch index.")
    } # nocov end

    store_searchindex_metadata(path, archive_path)
  } else if (!quiet && is.null(country)) {
    cli::cli_inform(c("i" = paste(
      "No search index downloaded!",
      "Download one or import from a Nominatim database."
    )))
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
      os <- ifelse(info$opensearch, "OpenSearch", "ElasticSearch")
      info <- c(
        if (x$is_running()) cli::col_yellow("Live now!"),
        sprintf("Type     : %s", type),
        sprintf("Version  : %s (%s)", info$version, os),
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


construct_jar <- function(version = NULL, opensearch = FALSE) {
  version <- version %||% get_latest_photon()
  opensearch <- ifelse(opensearch, "-opensearch", "")
  sprintf("photon%s-%s.jar", opensearch, version)
}
