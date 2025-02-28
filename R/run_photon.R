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
  logs <- list()
  stderr <- run(
    "java",
    args = args,
    stdout = "|",
    stderr = "|",
    echo_cmd = globally_enabled("photon_debug"),
    wd = self$path,
    timeout = timeout,
    error_on_status = FALSE,
    stderr_callback = log_callback(private, quiet = TRUE),
    stdout_callback = log_callback(private, quiet)
  )$stderr

  versionize_logs(private)
  abort_log_error(stderr, quiet, class = "import_error")
}


run_start <- function(self, private, args, timeout = 60, quiet = FALSE) {
  proc <- process$new(
    "java",
    args = args,
    stdout = "|",
    stderr = "|",
    echo_cmd = globally_enabled("photon_debug"),
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

  self$proc <- proc
  start_supervise(self, private, proc, timeout, quiet)
  versionize_logs(private)
  log_error <- assemble_log_error(private$logs)
  abort_log_error(log_error, quiet, class = "start_error")

  if (!self$is_running() && !nzchar(log_error)) {
    ph_stop(c( # nocov start
      "Unknown error occured during setup.",
      "i" = "Photon stopped unexpectedly."
    )) # nocov end
  }


  cli::cli_progress_done()
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


start_supervise <- function(self, private, proc, timeout, quiet) {
  stdout_callback <- log_callback(private, quiet)
  stderr_callback <- log_callback(private, quiet = TRUE)
  start <- Sys.time()
  is_running <- self$is_running()
  while (!is_running) {
    out <- proc$read_output()
    out <- strsplit(out, "\r\n")[[1]]
    lapply(out, stdout_callback, proc)

    err <- proc$read_error()
    stderr_callback(err, proc)
    if (nzchar(err)) next # skip alive check to collect full error message

    # if photon process is dead, break the loop and collect stderr afterwards
    if (!is_running && !proc$is_alive()) {
      break
    }

    # evaluate timeout error at the latest possible chance to allow supervisor
    # to throw a more useful error
    diff <- Sys.time() - start
    if (diff > timeout) {
      ph_stop("Photon setup timeout reached.") # nocov
    }

    Sys.sleep(0.1) # debounce
    is_running <- self$is_running()
  }
}


log_callback <- function(private, quiet = FALSE) {
  function(newout, proc) {
    if (length(newout) > 0 && isTRUE(nzchar(newout))) {
      log <- handle_log_conditions(newout)
      new_log <- list(private$logs %||% data.frame(), log)
      private$logs <- as_data_frame(rbind_list(new_log))
      if (!quiet) cli::cli_verbatim(newout)
    }
  }
}


handle_log_conditions <- function(out) {
  out <- split_by_logs_entry(out)
  log <- parse_log_line(out)
  is_usage_error <- grepl("Usage: <main class> [options]", out, fixed = TRUE)
  is_warning <- log$type %in% "WARN"
  is_exception <- grepl("exception", log$msg, ignore.case = TRUE) &
                     (log$class %in% "stderr" | is.na(log$type))

  if (any(is_warning) && globally_enabled("photon_setup_warn")) {
    for (msg in log$msg[is_warning]) cli::cli_warn(msg)
  }

  if (any(is_exception)) {
    log$type[is_exception] <- rep("ERROR", sum(is_exception))
  }

  if (any(is_usage_error)) {
    n_err <- sum(is_usage_error)
    log$type[is_usage_error] <- rep("ERROR", n_err)
    log$msg[is_usage_error] <- rep(
      paste(
        "Process returned a usage error.",
        "Verify that you passed valid command line options."
      ),
      n_err
    )
  }

  log
}


split_by_logs_entry <- function(logs) {
  rgx <- "(?<=\n)(?=Usage|[0-9]{4}-[0-9]{1,2}-[0-9]{1,2})"
  logs <- strsplit(logs, rgx, perl = TRUE)[[1]]
  unlist(logs)
}


parse_log_line <- function(line) {
  # photon logs have to different forms:
  # 1. timestamp [main] INFO trace - message
  # 2. [timestamp] [INFO] [stream] message
  # if 1. matches nothing, try 2.
  parsed <- utils::strcapture(
    "^(.+) \\[(.+)\\] (INFO|WARN)  (.+) - (.+)$",
    line,
    proto = list(ts = "", thread = "", type = "", class = "", msg = "")
  )

  if (all(is.na(parsed))) {
    parsed <- utils::strcapture(
      "\\[(.+)\\]\\[(.+)\\]\\[([a-zA-Z.]+) *?\\](.+)",
      line,
      proto = list(ts = "", type = "", class = "", msg = "")
    )
  }

  if (all(is.na(parsed))) {
    parsed <- data.frame(
      ts = NA_character_,
      thread = NA_character_,
      type = NA_character_,
      class = NA_character_,
      msg = line
    )
  }

  parsed$type <- trimws(parsed$type)
  parsed$msg <- trimws(parsed$msg)
  parsed
}


versionize_logs <- function(private) {
  logs <- private$logs
  if (is.null(logs)) return() # nocov

  # add a "run id" to versionize log dataframe
  # this is necessary so that subsequent calls know what the current call is
  if ("rid" %in% names(logs)) {
    rid <- max(logs$rid, na.rm = TRUE) + 1
    logs[is.na(logs$rid), "rid"] <- rid
  } else {
    logs <- as_data_frame(cbind(rid = 1, logs))
  }
  private$logs <- logs
}


assemble_log_error <- function(logs) {
  if (!is.null(logs)) {
    errs <- logs[logs$type %in% "ERROR" & logs$rid == max(logs$rid), ]
    paste(errs$msg, collapse = "")
  }
}


abort_log_error <- function(logerr, quiet, ...) {
  if (!is.null(logerr) && nzchar(logerr)) {
    if (!quiet) cli::cli_verbatim(logerr)
    ph_stop(c(
      strsplit(logerr, "\n")[[1]][1],
      "i" = "See logs for details."
    ), ..., call = NULL)
  }
}


build_photon_name <- function(version, opensearch) {
  ifelse(
    opensearch,
    sprintf("photon-opensearch-%s.jar", version),
    sprintf("photon-%s.jar", version)
  )
}


get_photon_executable <- function(path, version, opensearch) {
  file <- build_photon_name(version, opensearch)

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

  can_access_photon(self$get_url())
}


can_access_photon <- function(url) {
  req <- httr2::request(url)
  req <- httr2::req_template(req, "GET api")
  req <- httr2::req_error(req, is_error = function(r) FALSE)

  status <- tryCatch(
    httr2::req_perform(req)$status_code,
    error = function(e) 999
  )

  identical(status, 400L)
}
