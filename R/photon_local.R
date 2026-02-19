#' Local photon instance
#' @description
#' This R6 class is used to initialize and manage local photon instances.
#' It can download and setup the Java, the photon executable, and the necessary
#' OpenSearch index. It can start, stop, and query the status of the
#' photon instance. It is also the basis for geocoding requests as it is used
#' to retrieve the URL for geocoding.
#'
#' @section Search indices:
#' Search indices can be self-provided by importing an existing
#' Nominatim database or they can be downloaded from the
#' \href{https://nominatim.org/2020/10/21/photon-country-extracts.html}{Photon download server}.
#' If you want to download pre-built search indices, simply provide a
#' \code{region} string during initialization or use the
#' \code{$download_data} method. Pre-built search indices do not come with
#' support for structured geocoding.
#'
#' If you want to build from Nominatim, do not
#' provide a region string and use the \code{$import()} method. See
#' \code{vignette("nominatim-import", package = "photon")} for details on how
#' to import from Nominatim.
#'
#' To enable structured geocoding, the photon geocoder needs to be built to
#' support OpenSearch. Since photon 0.7.0, OpenSearch jar files are the
#' standard and ElasticSearch is deprecated.
#'
#' @export
#' @import R6
#'
#' @examplesIf getFromNamespace("is_online", "photon")("graphhopper.com") && getFromNamespace("photon_run_examples", "photon")()
#' if (has_java("11")) {
#' dir <- file.path(tempdir(), "photon")
#'
#' # start a new instance using a Monaco extract
#' photon <- new_photon(path = dir, region = "Andorra")
#'
#' # start a new instance with an older photon version
#' photon <- new_photon(path = dir, photon_version = "0.4.1", opensearch = FALSE)
#' }
#'
#' \dontrun{
#' # import a nominatim database using OpenSearch photon
#' # this example requires the OpenSearch version of photon and a running
#' # Nominatim server.
#' photon <- new_photon(path = dir, opensearch = TRUE)
#' photon$import(photon_options = cmd_options(port = 29146, password = "pgpass"))}
#'
#' photon$purge(ask = FALSE)
photon_local <- R6::R6Class(
  inherit = photon,
  classname = "photon_local",
  public = list(
    # Public ----
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
    #' should be stored.
    #' @param photon_version Version of photon to be used. A list of all
    #' releases can be found here: \url{https://github.com/komoot/photon/releases/}.
    #' Ignored if \code{jar} is given. If \code{NULL}, uses the latest known
    #' version (Currently: `r get_latest_photon()`).
    #' @param region Character string that identifies a region or country. An
    #' extract for this region will be downloaded. If \code{"planet"}, downloads
    #' a global extract (see note). Run \code{list_regions()} to get an overview
    #' of available regions. You can specify countries using any code that can
    #' be translated by \code{\link[countrycode]{countrycode}}.
    #' @param opensearch Deprecated for photon versions >= 1.0.0 and superseded
    #' for photon versions >= 0.7.0. If \code{TRUE},
    #' attempts to download the OpenSearch version of photon. OpenSearch-based
    #' photon supports structured geocoding. If \code{FALSE}, falls back to
    #' ElasticSearch. Since photon 0.7.0, OpenSearch is the default and since
    #' 1.0.0, ElasticSearch is not supported anymore.
    #' @param mount If \code{TRUE}, mounts the object to the session so that
    #' functions like \code{\link{geocode}} automatically detect the new
    #' instance. If \code{FALSE}, initializies the instance but doesn't mount
    #' it to the session. Defaults to \code{TRUE}.
    #' @param overwrite If \code{TRUE}, overwrites existing jar files and
    #' search indices when initializing a new instance. Defaults to
    #' \code{FALSE}.
    #' @param quiet If \code{TRUE}, suppresses all informative messages.
    initialize = function(path,
                          photon_version = NULL,
                          region = NULL,
                          opensearch = TRUE,
                          mount = TRUE,
                          overwrite = FALSE,
                          quiet = FALSE) {
      assert_flag(quiet)
      assert_flag(opensearch)
      check_jdk_version("11", quiet = quiet)
      photon_version <- photon_version %||% get_latest_photon()
      check_opensearch(opensearch, photon_version)

      path <- normalizePath(path, "/", mustWork = FALSE)
      if (!dir.exists(path)) {
        dir.create(path, recursive = TRUE) # nocov
      }

      setup_photon_directory(
        path,
        photon_version,
        region = region,
        opensearch = opensearch,
        overwrite = overwrite,
        quiet = quiet
      )

      self$path <- path
      private$quiet <- quiet
      private$version <- photon_version
      private$opensearch <- opensearch

      meta <- private$get_metadata(quiet = quiet)
      private$region <- meta$region
      private$date <- meta$date
      if (mount) self$mount()
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
    #' as the region and creation date of the search index.
    #' @return A list containing the java version, the photon version, and
    #' if applicable, the spatial and temporal coverage of the search index.
    info = function() {
      info <- list(java = get_java_version(quiet = TRUE))
      c(info, private$get_metadata(quiet = TRUE))
    },

    #' @description
    #' Print the default arguments to the R console. This can be helpful to
    #' get a list of additional photon arguments for \code{$start()} or
    #' \code{$import()}.
    #' @return Nothing, but prints to the console.
    help = function() {
      cat(run_photon(self, private, mode = "help", photon_opts = "-h")$stdout)
    },

    #' @description
    #' Kill the photon process and remove the directory. Useful to get rid
    #' of an instance entirely.
    #' @param ask If \code{TRUE}, asks for confirmation before purging the
    #' instance.
    #' @return \code{NULL}, invisibly.
    purge = function(ask = TRUE) {
      if (interactive() && ask) {
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
    #' @param java_opts Character vector of further flags passed on to the
    #' \code{java} command.
    #' @param photon_opts Character vector of further flags passed on to the
    #' photon jar in the java command. See \code{\link{cmd_options}} for a
    #' helper function.
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
      assert_vector(host, "character", size = 1)
      assert_vector(database, "character", size = 1)
      assert_vector(user, "character", size = 1)
      assert_vector(password, "character", size = 1)
      assert_vector(languages, "character", null = TRUE)
      assert_vector(countries, "character", null = TRUE)
      assert_vector(extra_tags, "character", null = TRUE)
      assert_vector(timeout, "numeric", size = 1)
      assert_vector(java_opts, "character", null = TRUE)
      assert_vector(photon_opts, "character", null = TRUE)
      assert_flag(structured)
      assert_flag(update)
      assert_flag(enable_update_api)
      assert_flag(json)

      if (structured && !private$opensearch) {
        cli::cli_warn(paste( # nocov start
          "Structured queries are only supported for OpenSearch photon.",
          "Setting {.code structured = FALSE}."
        ), class = "structured_elasticsearch_error")
        structured <- FALSE
      } # nocov end

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

      self$mount() # nocov
      invisible(self) # nocov
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
    #' @param java_opts Character vector of further flags passed on to the
    #' \code{java} command.
    #' @param photon_opts Character vector of further flags passed on to the
    #' photon jar in the java command. See \code{\link{cmd_options}} for a
    #' helper function.
    #'
    #' @details
    #' While there is a certain way to determine if a photon instance is
    #' ready, there is no clear way as of yet to determine if a photon setup
    #' has failed. Due to this, a failing setup may sometimes hang instead of
    #' emitting an error. In this case, please open a bug report.
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

      if (self$is_ready()) {
        ph_stop(
          c(
            "A photon instance is already running on {.url {self$get_url()}}.",
            "i" = "You can try to use a different port using `$start(port = ...)`."
          ),
          class = "photon_already_running"
        )
      }

      popts <- cmd_options(listen_ip = host, listen_port = port)
      cleanup <- function(e) self$stop()
      withCallingHandlers(
        run_photon(
          self, private,
          mode = "start",
          java_opts = java_opts,
          photon_opts = c(popts, photon_opts)
        ),
        error = cleanup,
        interrupt = cleanup
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
    #' Downloads a search index using \code{\link{download_database}}.
    #' @param region Character string that identifies a region or country. An
    #' extract for this region will be downloaded. If \code{"planet"}, downloads
    #' a global extract (see note). Run \code{list_regions()} to get an overview
    #' of available regions. You can specify countries using any code that can
    #' be translated by \code{\link[countrycode]{countrycode}}.
    #' @param json Extracts come in two forms: JSON dumps and pre-build databases.
    #' Pre-built databases are more convenient but less flexible and are not available
    #' for all regions. If you wish or need to build your own database, set
    #' \code{json = TRUE} and use the \code{$import()} method.
    download_data = function(region) {
      archive_path <- download_database(
        region = region,
        path = self$path,
        quiet = private$quiet,
        version = private$version
      )
      untar_index(archive_path, self$path)
      store_index_metadata(self$path, archive_path)
      invisible(self)
    },

    #' @description
    #' Removes the data currently used in the photon directory. This only
    #' affects the unpacked \code{photon_data} directory, not archived files.
    remove_data = function() {
      status <- unlink(
        file.path(self$path, "photon_data"),
        recursive = TRUE,
        force = TRUE
      )

      if (!identical(status, 0L)) {
        cli::cli_warn(c(
          "Photon data could not be removed.",
          "i" = "Is photon still running?"
        ), class = "photon_data_not_removed")
      }

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
    #' @return A logical of length 1.
    is_running = function() {
      photon_running(self)
    },

    #' @description
    #' Checks whether the photon instance is ready to take requests. This
    #' is the case if the photon server returns a HTTP 400 when sending a
    #' queryless request. This method is useful if you want to check whether
    #' you can send requests.
    #' @return A logical of length 1.
    is_ready = function() {
      photon_ready(self, private)
    },

    #' @description
    #' Constructs the URL that geocoding requests should be sent to.
    #' @return A URL to send requests to.
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
    },

    #' @description
    #' Retrieve the logs of previous photon runs.

    #' @return Returns a dataframe containing the run ID (\code{rid}, the
    #' highest number is the most recent run), a timestamp (\code{ts}), the
    #' thread, the log type (INFO, WARN, or ERROR), the class trace and the
    #' error message.
    get_logs = function() {
      private$logs
    }
  ),

  private = list(
    # Private ----
    quiet = FALSE,
    version = NULL,
    host = NULL,
    port = NULL,
    ssl = NULL,
    region = NULL,
    date = NULL,
    opensearch = NULL,
    logs = NULL,
    finalize = function() {
      self$stop() # nocov
    },
    get_metadata = function(quiet = TRUE) {
      meta_path <- file.path(self$path, "photon_data", "rmeta.rds")

      if (!file.exists(meta_path)) {
        # if photon_data has been created outside of {photon}, metadata cannot be retrieved
        meta <- list(region = NULL, date = NULL) # nocov
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
          sprintf("Coverage: %s", meta$region %|||% NULL),
          sprintf("Time: %s", meta$date %|||% NULL)
        ))
      }

      meta
    }
  )
)


# External ----
setup_photon_directory <- function(path,
                                   version,
                                   region = NULL,
                                   opensearch = FALSE,
                                   overwrite = FALSE,
                                   quiet = FALSE) {
  jar <- construct_jar(version, opensearch)

  files <- list.files(path, full.names = TRUE)
  if (!jar %in% basename(files) || overwrite) {
    download_photon(
      path = path,
      version = version,
      opensearch = opensearch,
      quiet = quiet
    )
  } else if (!quiet) {
    inform_photon_exists()
  }

  if (!any(grepl("photon_data$", files)) || overwrite) {
    has_archive <- grepl("\\.bz2$", files)
    if ((!any(has_archive) || overwrite) && !is.null(region)) {
      section <- if (opensearch) "experimental" else section
      archive_path <- download_database(
        path = path,
        region = region,
        version = version,
        quiet = quiet
      )
    } else if (!any(has_archive)) {
      inform_no_download()
      return()
    } else {
      inform_tar_exists() # nocov
      archive_path <- files[has_archive] # nocov
    }

    untar_index(archive_path, path)
    store_index_metadata(path, archive_path)
  } else if (!quiet) {
    inform_index_exists()
  }
}


untar_index <- function(archive_path, path) {
  untared <- utils::untar(archive_path, files = "photon_data", exdir = path)

  if (!identical(untared, 0L)) {
    ph_stop("Failed to untar search index.") # nocov
  }
}


store_index_metadata <- function(path, archive_path) {
  # legacy file name scheme
  meta <- utils::strcapture(
    pattern = "photon-db-?([a-z]{2})?-([0-9]+|latest)\\.tar\\.bz2",
    x = basename(archive_path),
    proto = data.frame(region = character(), date = character())
  )

  if (all(is.na(meta))) {
    meta <- utils::strcapture(
      pattern = "photon-db-(.+)-(\\d+\\.\\d+)-([0-9]+|latest)\\.tar\\.bz2",
      x = basename(archive_path),
      proto = data.frame(region = character(), build_version = character(), date = character())
    )
  }

  # if a date is missing from the file name, set the current date
  meta$date <- if (identical(meta$date, "latest")) Sys.Date() else meta$date
  meta$date <- as.POSIXct(meta$date, format = "%y%m%d")

  # if a region is missing from the file name, it is likely global
  meta$region <- ifelse(
    nzchar(meta$region),
    to_title(gsub("-", " ", meta$region)),
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
        sprintf("Coverage : %s", info$region),
        sprintf("Time     : %s", info$date),
        sprintf("Database built for photon %s", info$build_version)
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


check_opensearch <- function(opensearch, version) {
  version <- numeric_version(version)
  if (version >= "0.7.0" && !opensearch) {
    cli::cli_warn(c( # nocov start
      "!" = "ElasticSearch versions are superseded for photon 0.7.0 or higher.",
      "i" = "You can set opensearch = TRUE, to use OpenSearch instead."
    ))
  } else if (version >= "1.0.0" && !opensearch) {
    cli::cli_abort(c(
      "!" = "Since photon 1.0.0, ElasticSearch is not supported anymore.",
      "i" = "Set `opensearch = TRUE` to use OpenSearch instead."
    )) # nocov end
  }
}


inform_no_download <- function() {
  cli::cli_inform(c("i" = paste(
    "No search index downloaded!",
    "Download one or import from a Nominatim database."
  )))
}


inform_index_exists <- function() {
  cli::cli_inform(c("i" = paste(
    "A search index already exists at the given path.",
    "Download will be skipped"
  )))
}


inform_photon_exists <- function() {
  cli::cli_inform(c("i" = paste(
    "A photon executable already exists in the given path.",
    "Download will be skipped."
  )))
}


inform_tar_exists <- function() {
  cli::cli_inform(c("i" = paste( # nocov start
    "A search index archive already exists at the given path.",
    "Download will be skipped"
  ))) # nocov end
}
