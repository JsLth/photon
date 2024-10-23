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
#' or \code{tasklist} (in Windows). Tasks are killed using \code{pkill}
#' (on Linux and MacOS) or \code{Taskkill} (on Windows).
#'
#' @export
#'
#' @examples
#' if (FALSE) {
#' purge_java() # should do nothing
#'
#' # start a new photon instance
#' dir <- file.path(tempdir(), "photon")
#' photon <- new_photon(dir, country = "Samoa")
#' photon$start()
#'
#' # kill photon using a sledgehammer
#' purge_java()
#' }
purge_java <- function(pids = NULL, consent = FALSE) {
  procs <- get_java_processes()

  if (!nrow(procs)) {
    cli::cli_inform("No java processes running.")
    return(invisible(NULL))
  }

  check_pid_is_java(procs, pids)
  cli::cli_inform("The following Java instances have been found:\f")
  cli::cli_verbatim(capture.output(procs))

  if (interactive() && !consent) {
    if (is.null(pids)) {
      cli::cli_inform("\fThis action will force all Java instances to close.")
    } else {
      cli::cli_inform("\fThis action will force the following PIDs to close: {pid}")
    }

    yes_no("Continue?", no = cancel("Function call aborted."))
  }

  pids <- pids %||% procs$pid
  kill_java(pids)
}


check_pid_is_java <- function(procs, pid) {
  is_java_pid <- pid %in% procs$pid
  if (!is.null(pid) && !all(is_java_pid)) {
    cli::cli_abort(c(
      "The following PIDs are not PIDs related to Java: {pid[is_java_pid]}",
      "i" = "Be cautious when passing PIDs to kill!"
    ))
  }
}


kill_java <- function(pids) {
  codes <- NULL
  if (is_linux() || is_macos()) {
    for (pid in pids) {
      status <- callr::run("pkill", args = c("-9", pid))$status
      codes <- c(codes, status)
    }
  } else {
    for (pid in pids) {
      status <- callr::run("Taskkill", args = c("/PID", pid, "/F"))$status
      codes <- c(codes, status)
    }
  }
  codes
}


get_java_processes <- function() {
  if (is_linux() || is_macos()) {
    procs <- callr::run("ps", "-A", stdout = NULL, stderr = NULL)
    procs <- utils::read.table(procs, header = TRUE)
    names(procs) <- c("pid", "tty", "time", "cmd")
  } else if (is_windows()) {
    procs <- callr::run("tasklist", args = c("/FO", "CSV"))$stdout
    procs <- utils::read.csv(text = procs, header = TRUE)
    names(procs) <- c("cmd", "pid", "session_name", "session", "mem_usage")
  }

  procs <- procs[grepl("java.exe", procs$cmd, fixed = TRUE), ]
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
