#' Purge Java processes
#' @description
#' Kill all or selected running Java processes. This function is useful to
#' stop Photon instances when not being able to kill the
#' \code{\link[processx]{process}} objects. Be aware that you can also
#' kill Java processes other than the photon application using this function!
#'
#' @param pids PIDs to kill. The PIDs should be Java processes. If \code{NULL},
#' tries to kill all Java processes.
#' @param consent If \code{FALSE}, asks for consent before killing the
#' processes. Defaults to \code{FALSE}.
#'
#' @returns An integer vector of the \code{pkill} / \code{Taskkill} status
#' codes or \code{NULL} if not running Java processes are found.
#'
#' @details
#' A list of running Java tasks is retrieved using \code{ps} (on Linux and MacOS)
#' or \code{tasklist} (on Windows). Tasks are killed using \code{pkill}
#' (on Linux and MacOS) or \code{Taskkill} (on Windows).
#'
#' @export
#'
#' @examples
#' # NOTE: These examples should only be run interactively or when you are
#' # sure that no other java processes are running simultaneously!
#' \dontrun{
#' purge_java() # does nothing if no java processes are running
#'
#' # start a new photon instance
#' dir <- file.path(tempdir(), "photon")
#' photon <- new_photon(dir, country = "Samoa")
#' photon$start()
#'
#' # kill photon using a sledgehammer
#' purge_java()
#'
#' photon$start()
#'
#' # kill photon using a scalpel
#' library(ps)
#' p <- ps_handle(photon$proc$get_pid())
#' pids <- sapply(ps_children(p), ps::ps_pid)
#' purge_java(pids)}
purge_java <- function(pids = NULL, consent = FALSE) {
  assert_vector(pids, "numeric", null = TRUE)
  assert_flag(consent)
  procs <- get_java_processes()

  if (!nrow(procs)) {
    cli::cli_inform("No java processes running.")
    return(invisible(NULL))
  }

  check_pid_is_java(procs, pids)
  cli::cli_inform("The following Java instances have been found:\f") # nocov start
  cli::cli_verbatim(utils::capture.output(procs))

  if (interactive() && !consent) {
    if (is.null(pids)) {
      cli::cli_inform("\fThis action will force all Java instances to close.")
    } else {
      cli::cli_inform("\fThis action will force the following PIDs to close: {pid}")
    }

    yes_no("Continue?", no = cancel("Function call aborted."))
  }

  pids <- pids %||% procs$pid
  kill_process(pids) # nocov end
}


check_pid_is_java <- function(procs, pid) {
  is_java_pid <- pid %in% procs$pid
  if (!is.null(pid) && !all(is_java_pid)) {
    ph_stop(c(
      "The following PIDs are not PIDs related to Java: {pid[!is_java_pid]}",
      "i" = "Be cautious when passing PIDs to kill!"
    ), class = "pid_not_java")
  }
}


kill_process <- function(pids) {
  if (is_linux() || is_macos()) {
    codes <- vapply(pids, FUN.VALUE = integer(1), function(pid) { # nocov start
      args <- c("-9", pid)
      run("pkill", args = args, error_on_status = FALSE)$status
    }) # nocov end
  } else {
    codes <- vapply(pids, FUN.VALUE = integer(1), function(pid) {
      args <- c("/PID", pid, "/F")
      run("Taskkill", args = args, error_on_status = FALSE)$status
    })
  }
  codes
}


get_java_processes <- function() {
  if (is_linux()) {
    args <- c("-eo", "pid,comm,tty,user,pmem") # nocov start
    procs <- run("ps", args = args)$stdout
    # to-do: is there a safer alternative? fill = TRUE is an interim hack
    procs <- utils::read.csv(text = procs, header = TRUE, fill = TRUE)
    for (col in names(t)) t[, col] <- trimws(t[, col])
    names(procs) <- c("cmd", "pid", "tty", "user", "memory")
  } else if (is_macos()) {
    args <- c(
      "-A", "-e", "-o", "ucomm,", "-o", "pid,",
      "-o", "tty,", "-o", "user,", "-o", "%mem"
    )
    procs <- run("ps", args = args)$stdout
    # to-do: is there a safer alternative? fill = TRUE is an interim hack
    procs <- utils::read.table(text = procs, header = TRUE, fill = TRUE)
    names(procs) <- c("cmd", "pid", "tty", "user", "memory") # nocov end
  } else if (is_windows()) {
    args <- c("/FO", "CSV")
    procs <- run("tasklist", args = args)$stdout
    procs <- utils::read.csv(text = procs, header = TRUE)
    names(procs) <- c("cmd", "pid", "session_name", "session", "memory")
  }

  procs <- procs[grepl("java", procs$cmd, fixed = TRUE), ]
  row.names(procs) <- NULL
  procs
}


is_windows <- function() {
  .Platform$OS.type == "windows"
}


is_linux <- function() {
  Sys.info()["sysname"] == "Linux"
}


is_macos <- function() {
  Sys.info()["sysname"] == "Darwin"
}
