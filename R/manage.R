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
#' \code{\link{photon}} for details.
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
      private$mount()
    },

    get_url = function() {
      private$url
    }
  ),

  private = list(
    ## private ----
    url = NULL,
    mount = function() assign("instance", self, envir = photon_env)
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
#' @import R6
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
    #' @param exact If \code{TRUE}, exactly matches the \code{date}. Otherwise,
    #' selects the date with lowest difference to the \code{date} parameter.
    #' @param quiet If \code{TRUE}, suppresses all informative messages.
    initialize = function(path = "./photon",
                          photon_version = NULL,
                          country = NULL,
                          date = "latest",
                          exact = FALSE,
                          quiet = FALSE) {
      assert_true_or_false(quiet)
      check_jdk_version(11)

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
        quiet = quiet
      )
      meta <- show_metadata(path)

      self$path <- path
      private$quiet <- quiet
      private$version <- meta$version
      private$country <- meta$country
      private$date <- meta$date
      private$mount()
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
    #' @param java_options List of further flags passed on to the \code{java}
    #' command.
    #' @param photon_options List of further flags passed on to the photon
    #' jar in the java command.
    start = function(min_ram = 5,
                     max_ram = 10,
                     host = "0.0.0.0",
                     port = "2322",
                     ssl = FALSE,
                     java_options = NULL,
                     photon_options = NULL) {
      assert_vector(min_ram, "double")
      assert_vector(max_ram, "double")
      assert_vector(host, "character")
      private$host <- host
      private$port <- port
      private$ssl <- ssl
      self$proc <- start_photon(
        path = self$path,
        version = private$version,
        min_ram = min_ram,
        max_ram = max_ram,
        host = host,
        port = port,
        java_options = java_options,
        photon_options = photon_options,
        quiet = private$quiet
      )
      private$mount()
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

      if (identical(host, "0.0.0.0")) host <- "localhost"
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
    mount = function() {
      assign("instance", self, envir = photon_env)
    },
    finalize = function() {
      self$stop() # nocov
    }
  )
)


# External ----
start_photon <- function(path,
                         version,
                         min_ram = 6,
                         max_ram = 12,
                         host = "0.0.0.0",
                         port = "2322",
                         java_options = NULL,
                         photon_options = NULL,
                         quiet = FALSE) {
  exec <- sprintf("photon-%s.jar", version)

  if (!length(exec)) {
    cli::cli_abort("Photon executable not found in the given {.var path}.") # nocov
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
    echo_cmd = getOption("photon_debug", FALSE),
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

    if (nzchar(out) && !quiet) cli::cli_verbatim(out)

    if (nzchar(err)) {
      stop(err) # nocov
    }
  }

  invisible(proc)
}


stop_photon <- function(self) {
  if (self$is_running()) {
    self$proc$kill_tree()
  }

  if (self$is_running()) { # nocov start
    self$proc$interrupt()
  }

  if (self$is_running()) {
    cli::cli_warn(c(
      "!" = "Failed to stop photon server.",
      "i" = "If the problem persists, restart the R session."
    ))
  } # nocov end
}


photon_running <- function(self) {
  (inherits(self$proc, "process") && self$proc$is_alive()) || self$is_ready()
}


photon_ready <- function(self, private) {
  if (is.null(private$host)) {
    return("not ready")
  }

  req <- httr2::request(self$get_url())
  req <- httr2::req_template(req, "GET api")
  req <- httr2::req_error(req, is_error = function(r) FALSE)

  status <- tryCatch(
    httr2::req_perform(req)$status_code,
    error = function(e) 999
  )

  identical(status, 400L)
}


setup_photon_directory <- function(path, version, ..., quiet = FALSE) {
  files <- list.files(path, full.names = TRUE)
  if (!any(grepl("\\.jar$", files))) {
    download_photon(path = path, version = version, quiet = quiet)
  } else {
    cli::cli_inform(c("i" = paste(
      "A photon executable already exists in the given path.",
      "Download will be skipped."
    )))
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
  } else {
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


show_metadata <- function(path) {
  meta <- get_metadata(path)

  cli::cli_ul(c(
    sprintf("Version: %s", meta$version),
    sprintf("Coverage: %s", meta$country),
    sprintf("Time: %s", meta$date)
  ))

  meta
}


check_jdk_version <- function(version, quiet = FALSE) {
  version <- numeric_version(get_java_version(quiet))
  min_version <- numeric_version(version)

  if (version < min_version) {
    msg <- c("!" = "JDK version {version} detected but version 17 required.", rje_link)
    ph_stop(msg, class = "java_version_error")
  }
}


has_java <- function() {
  any(as.logical(nchar(Sys.which("java"))))
}


rje_link <- function() {
  link <- cli::style_hyperlink("{rJavaEnv}", "https://www.ekotov.pro/rJavaEnv/")
  c("i" = "Consider setting up a Java environment with {.code {link}}")
}


get_java_version <- function(quiet = FALSE) {
  if (!has_java()) {
    msg <- c("!" = "JDK required but not found.", rje_link)
    ph_stop(msg, class = "java_missing_error", call = NULL)
  }

  version <- processx::run("java", "-version", error_on_status = TRUE)$stderr
  version <- gsub("\n", "\f", gsub("\r", "", version))

  if (!quiet) {
    version_fmt <- strsplit(version, "\f")[[1]]
    names(version_fmt) <- rep("i", length(version_fmt))
    cli::cli_inform(version_fmt)
  }

  version <- regex_match(
    version,
    "(openjdk|java) (version )?(\\\")?([0-9]{1,2})",
    perl = TRUE,
    i = 5
  )
  version
}

get_photon_version <- function(path) {
  file <- list.files(path, pattern = "photon-.+\\.jar$")[[1]]
  regex_match(file, "photon-(.+)\\.jar", i = 2)
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
