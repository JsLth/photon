check_jdk_version <- function(min_version, quiet = FALSE) {
  version <- get_java_version(quiet)

  if (!minimum_version(version, min_version)) {
    msg <- c("!" = "JDK version {version} detected but version 17 required.", rje_link())
    ph_stop(msg, class = "java_version_error")
  }
}


#' Is Java installed?
#' @description
#' Utility function to check if Java is installed and if it has the right
#' version.
#'
#' @param version Character string specifying the minimum version of Java.
#' If the installed Java version is lower than this, returns \code{FALSE}.
#' If \code{NULL}, only checks if any kind of Java is installed on the
#' system.
#'
#' @returns A logical vector of length 1.
#'
#' @export
#'
#' @examples
#' has_java() # Is Java installed?
#' has_java("11") # Is Java > 11 installed?
has_java <- function(version = NULL) {
  assert_vector(version, "character", size = 1, null = TRUE)
  has_tool <- file.exists(Sys.which("java"))

  if (is.null(version) || isFALSE(has_tool)) {
    return(has_tool)
  }

  sys_version <- get_java_version(quiet = TRUE)
  minimum_version(sys_version, version)
}


rje_link <- function() {
  c("i" = paste(
    'Consider setting up a Java environment with {.pkg',
    '{cli::style_hyperlink("{rJavaEnv}", "https://www.ekotov.pro/rJavaEnv/")}}'
  ))
}


get_java_version <- function(quiet = FALSE) {
  if (!has_java()) {
    msg <- c("!" = "JDK required but not found.", rje_link())
    ph_stop(msg, class = "java_missing_error", call = NULL)
  }

  version <- run("java", "-version", error_on_status = TRUE)$stderr
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
