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
    ))
  }

  instance
}

#' @rdname get_instance
#' @export
get_photon_url <- function() {
  instance <- get_instance()
  instance$get_url()
}

#' Initialize a photon instance
#' @description
#' Initialize a photon instance by creating a new photon object. This object
#' is stored in the R session and can be used to perform geocoding requests.
#'
#' Instances can either local or remote. Remote instances require nothing more
#' than a URL that geocoding requests are sent to. Local instances require the
#' setup of the photon executable, an Elasticsearch index, and Java. See
#' \code{\link{photon}} for details.
#'
#' @param path Path to a directory where the photon executable and data
#' should be stored. Defaults to a directory "photon" in the current
#' working directory. If \code{NULL}, a remote instance is set up based on
#' the \code{url} parameter.
#' @param url If \code{type = "public"}, specifies the URL that geocoding
#' requests are sent to. If \code{NULL} and \code{path} is also \code{NULL},
#' connects to the public API under \url{photon.komoot.io}.
#' @param ... Arguments passed to \code{\link{photon}$new()}.
#'
#' @returns An R6 object of class \code{photon}.
#'
#' @export
#'
#' @examples
#' # connect to public API
#' photon <- new_photon()
#'
#' \dontrun{
#' # connect to arbitrary server
#' photon <- new_photon(url = "photonserver.org")
#'
#' # set up a local instance
#' photon <- new_photon(path = tempdir())}
new_photon <- function(path = NULL, url = NULL, ...) {
  if (is.null(path) && is.null(url)) {
    photon_remote$new(url = "https://photon.komoot.io/")
  } else if (is.null(path)) {
    photon_remote$new(url = url)
  } else if (is.null(url)) {
    photon$new(...)
  }
}


photon_remote <- R6::R6Class(
  classname = "photon",
  public = list(
    initialize = function(url) {
      assert_url(url)
      private$url <- url
      private$mount()
    },

    get_url = function() {
      private$url
    }
  ),

  private = list(
    url = NULL,
    mount = function() assign("instance", self, envir = photon_env)
  )
)


#' Local photon instance
#' @description
#' This R6 class is used to initialize and manage local photon instances.
#' It can download and setup the Java, the photon executable, and the necessary
#' Elasticsearch search index. It can start, stop, and query the status of the
#' photon instance. It is also the basis for geocoding requests at it is used
#' to retrieve the URL for geocoding.
#'
#' @export
#'
#' @examples
#' if (FALSE) {
#' # start a new instance using a Monaco extract
#' photon <- new_photon(path = tempdir(), country = "Monaco")
#'
#' # start a new instance with an older photon version
#' photon <- new_photon(path = tempdir(), photon_version = "0.4.1")
#'
#' # start a new instance with a specific java version
#' photon <- new_photon(path = tempdir(), java_version = 17)
#' }
photon <- R6::R6Class(
  classname = "photon",
  public = list(
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
    #' @param java_version Java version to be used. See \code{\link[rJavaEnv]{use_java}}
    #' for available versions.
    #' @param ... Further arguments passed to \code{\link[rJavaEnv]{use_java}}.
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
    #' @param exact If \code{TRUE}, exactly matches the \code{date}. Otherwise,
    #' selects the date with lowest difference to the \code{date} parameter.
    #' @param consent Whether to provide consent to \code{rJavaEnv} to setup
    #' Java. See \code{\link[rJavaEnv]{rje_consent}}.
    #' @param quiet If \code{TRUE}, suppresses all informative messages.
    initialize = function(path = "./photon",
                          photon_version = NULL,
                          java_version = 22,
                          ...,
                          country = NULL,
                          date = "latest",
                          exact = FALSE,
                          consent = FALSE,
                          quiet = FALSE) {
      rJavaEnv::rje_consent(provided = consent)
      rJavaEnv::use_java(version = java_version, quiet = quiet, ...)

      path <- normalizePath(path, "/", mustWork = FALSE)
      if (!dir.exists(path)) {
        dir.create(path, recursive = TRUE)
      }

      photon_version <- photon_version %||% get_photon_version()
      setup_photon_directory(
        path,
        photon_version,
        country = country,
        date = date,
        exact = exact,
        quiet = quiet
      )

      self$path <- path
      private$consent <- consent
      private$quiet <- quiet
      private$version <- photon_version
      private$country
      private$mount()
    },

    #' @description
    #' Kill the photon process and remove the directory. Useful to get rid
    #' of an instance entirely.
    purge = function() {
      cli::cli_inform(paste(
        "Purging an instance kills the photon process",
        "and removes the photon directory."
      ))
      yes_no("Continue?", no = cancel())

      self$stop()
      unlink(self$path, recursive = TRUE, force = TRUE)
      invisible(NULL)
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
    #' @param java_options List of further flags passed on to the \code{java}
    #' command.
    #' @param photon_options List of further flags passed on to the photon
    #' jar in the java command.
    start = function(min_ram = 5,
                     max_ram = 10,
                     host = "0.0.0.0",
                     port = "2322",
                     java_options = NULL,
                     photon_options = NULL) {
      assert_vector(min_ram, "double")
      assert_vector(max_ram, "double")
      assert_vector(host, "character")
      private$host <- host
      private$port <- port
      self$proc <- start_photon(
        path = self$path,
        version = private$version,
        min_ram = min_ram,
        max_ram = max_ram,
        host = host,
        port = port,
        java_options = java_options,
        photon_options = photon_options,
        debug = !private$quiet
      )
      private$mount()
      invisible(self)
    },

    #' @description
    #' Kills the running photon process.
    stop = function() {
      stop_photon(self$proc)
    },

    #' @description
    #' Checks whether the photon instance is running.
    is_running = function() {
      photon_running(self$proc)
    },

    #' @description
    #' Constructs the URL that geocoding requests should be sent to.
    get_url = function() {
      host <- private$host
      port <- private$port

      if (is.null(host)) {
        ph_stop(c(
          "x" = "Photon server is not running.",
          "i" = "Start it by calling {.code $start()}"
        ))
      }

      if (identical(host, "0.0.0.0")) host <- "localhost"
      sprintf("https://%s:%s/", host, port)
    }
  ),

  private = list(
    consent = FALSE,
    quiet = FALSE,
    version = NULL,
    host = NULL,
    port = NULL,
    mount = function() {
      assign("instance", self, envir = photon_env)
    },
    finalize = function() {
      if (self$proc$is_alive()) {
        self$proc$kill()
      }
    }
  )
)


start_photon <- function(path,
                         version,
                         min_ram = 6,
                         max_ram = 12,
                         host = "0.0.0.0",
                         port = "2322",
                         java_options = NULL,
                         photon_options = NULL,
                         debug = FALSE) {
  exec <- sprintf("photon-%s.jar", version)

  if (!length(exec)) {
    cli::cli_abort("Photon executable not found in the given {.var path}.")
  }

  path <- normalizePath(path, winslash = "/")

  cmd <- c(
    sprintf("-Xms%sg", min_ram), sprintf("-Xmx%sg", max_ram), java_options,
    "-jar", exec, photon_options, "-listen-ip", host, "-listen-port", port
  )

  java <- Sys.which("java")
  proc <- processx::process$new(
    command = java,
    args = cmd,
    stdout = "|",
    stderr = "|",
    echo_cmd = debug,
    wd = path
  )

  cli::cli_progress_step(
    msg = "Starting photon...",
    msg_done = "Photon is now running.",
    msg_failed = "Photon could not be started."
  )

  out <- ""
  while (!grepl("ES cluster is now ready", out, fixed = TRUE)) {
    out <- proc$read_output()
    err <- proc$read_error()

    if (nzchar(out) && debug) cli::cli_verbatim(out)

    if (nzchar(err)) {
      stop(err)
    }
  }

  invisible(proc)
}


stop_photon <- function(proc) {
  if (proc$is_alive()) {
    proc <- proc$interrupt()
  }

  proc
}


photon_running <- function(proc) {
  if (is.environment(proc)) {
    proc$is_alive()
  } else {
    FALSE
  }
}


setup_photon_directory <- function(path, version, ..., quiet = FALSE) {
  files <- list.files(path)
  if (!any(grepl("\\.jar$", files))) {
    download_photon(path = path, version = version, quiet = quiet)
  }

  if (!"photon_data" %in% files) {
    has_archive <- grepl("\\.bz2$", files)
    if (!any(has_archive)) {
      archive_path <- download_searchindex(path = path, ..., quiet = quiet)
    } else {
      archive_path <- files[has_archive]
    }
    untar(archive_path, files = "photon_data", exdir = path)
  }
}
