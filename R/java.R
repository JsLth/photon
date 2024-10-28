check_jdk_version <- function(min_version, quiet = FALSE) {
  version <- numeric_version(get_java_version(quiet))
  min_version <- numeric_version(min_version)

  if (version < min_version) {
    msg <- c("!" = "JDK version {version} detected but version 17 required.", rje_link())
    ph_stop(msg, class = "java_version_error")
  }
}


has_java <- function() {
  any(nzchar(Sys.which("java")))
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
