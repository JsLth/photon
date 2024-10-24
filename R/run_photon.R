run_photon <- function(self, private, java_opts = NULL, photon_opts = NULL) {
  quiet <- private$quiet
  version <- private$version
  path <- self$path

  exec <- get_photon_executable(path, version)
  path <- normalizePath(path, winslash = "/")
  args <- c(java_opts, "-jar", exec, photon_opts)

  proc <- processx::process$new(
    "java",
    args = args,
    stdout = "|",
    stderr = "|",
    echo_cmd = globally_enabled("photon_debug", FALSE),
    wd = path
  )

  if (globally_enabled("photon_movers")) {
    cli::cli_progress_step(
      msg = "Starting photon...",
      msg_done = "Photon is now running.",
      msg_failed = "Photon could not be started.",
      spinner =
    )
  }

  while (!photon_ready(self, private)) {
    out <- proc$read_output()
    if (nzchar(out) && !quiet) {
      cli::cli_verbatim(out)
      handle_log_conditions(out)
    }

    err <- proc$read_error()
    if (nzchar(err)) {
      cli::cli_abort(err) # nocov
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


handle_log_conditions <- function(out) {
  warnings <- out[grepl("WARN", out, fixed = TRUE)]
  if (length(warnings) && globally_enabled("photon_setup_warn")) {
    msg <- parse_log_line(out)$msg
    cli::cli_warn(trimws(msg))
  }

  exceptions <- out[grepl("exception", out, ignore.case = TRUE)]
  if (length(exceptions)) {
    msg <- parse_log_line(out)$msg
    cli::cli_abort(trimws(msg))
  }

  if (startsWith(out, "Usage")) {
    cli::cli_abort("Process returned an error.")
  }
}


parse_log_line <- function(line) {
  line <- strcapture(
    "\\[(.+)\\]\\[(.+)\\]\\[([a-zA-Z. ]+)\\](.+)",
    line,
    proto = list(
      ts = character(),
      type = character(),
      stream = character(),
      msg = character()
    )
  )
}


get_photon_executable <- function(path, version) {
  if (has_opensearch_jar(path)) {
    file <- sprintf("photon-opensearch-%s.jar", version)
  } else {
    file <- sprintf("photon-%s.jar", version)
  }

  if (!file.exists(file.path(path, file))) {
    cli::cli_abort("Photon jar {.val {file}} could not be found in the given path.")
  }

  file
}


photon_running <- function(self) {
  (inherits(self$proc, "process") && self$proc$is_alive()) && self$is_ready()
}


photon_ready <- function(self, private) {
  if (is.null(private$host)) {
    return(FALSE)
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
