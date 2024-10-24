run_photon <- function(self,
                       private,
                       mode,
                       timeout = 60,
                       java_opts = NULL,
                       photon_opts = NULL) {
  quiet <- private$quiet
  version <- private$version
  path <- self$path

  exec <- get_photon_executable(path, version, private$opensearch)
  path <- normalizePath(path, winslash = "/")
  args <- c(java_opts, "-jar", exec, photon_opts)

  switch(
    mode,
    import = run_import(self, private, args, timeout, quiet),
    start = run_start(self, private, args, timeout, quiet)
  )
}


run_import <- function(self, private, args, timeout = 60, quiet = FALSE) {
  run(
    "java",
    args = args,
    stdout = "|",
    stderr = "|",
    echo_cmd = globally_enabled("photon_debug", FALSE),
    wd = self$path,
    timeout = timeout,
    error_on_status = TRUE,
    stdout_callback = function(newout, proc) {
      if (nzchar(newout) && !quiet) {
        cli::cli_verbatim(newout)
        handle_log_conditions(newout)
      }
    }
  )
}


run_start <- function(self, private, args, timeout = 60, quiet = FALSE) {
  proc <- process$new(
    "java",
    args = args,
    stdout = "|",
    stderr = "|",
    echo_cmd = globally_enabled("photon_debug", FALSE),
    wd = self$path
  )

  if (globally_enabled("photon_movers")) {
    cli::cli_progress_step(
      msg = "Starting photon...",
      msg_done = "Photon is now running.",
      msg_failed = "Photon could not be started.",
      spinner = TRUE
    )
  }

  start <- Sys.time()
  while (!photon_ready(self, private) && proc$is_alive()) {
    diff <- Sys.time() - start
    if (diff > timeout) {
      ph_stop("Photon setup timeout reached.")
    }

    out <- proc$read_output()
    if (nzchar(out) && !quiet) {
      cli::cli_verbatim(out)
      handle_log_conditions(out)
    }

    err <- proc$read_error()
    if (nzchar(err)) {
      ph_stop(err) # nocov
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
    if (!is.null(msg)) {
      cli::cli_warn(trimws(msg))
    }
  }

  # exceptions <- out[grepl("exception", out, ignore.case = TRUE)]
  # if (length(exceptions)) {
  #   msg <- parse_log_line(out)$msg
  #   ph_stop(trimws(msg))
  # }

  if (startsWith(out, "Usage")) {
    ph_stop("Process returned an error.")
  }
}


parse_log_line <- function(line) {
  # photon logs have to different forms:
  # 1. timestamp [main] INFO trace - message
  # 2. [timestamp] [INFO] [stream] message
  # if 1. matches nothing, try 2.
  parsed <- utils::strcapture(
    "^(.+) \\[(.+)\\] (INFO|WARN) (.+) - (.+)$",
    line,
    proto = data.frame(ts = "", src = "", type = "", trace = "", msg = "")
  )

  if (all(is.na(parsed))) {
    parsed <- utils::strcapture(
      "\\[(.+)\\]\\[(.+)\\]\\[([a-zA-Z. ]+)\\](.+)",
      line,
      proto = list(ts = "", type = "", src = "", msg = "")
    )
  }

  if (all(is.na(parsed))) {
    parsed <- NULL
  }

  parsed
}


get_photon_executable <- function(path, version, opensearch) {
  if (opensearch) {
    file <- sprintf("photon-opensearch-%s.jar", version)
  } else {
    file <- sprintf("photon-%s.jar", version)
  }

  if (!file.exists(file.path(path, file))) {
    ph_stop("Photon jar {.val {file}} could not be found in the given path.")
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
