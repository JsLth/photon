"%||%" <- function(x, y) {
  if (is.null(x)) y else x
}


ph_stop <- function(msg, env = parent.frame(), class = NULL, ...) {
  cli::cli_abort(msg, .envir = env, class = c(class, "ph_error"))
}


return_from_parent <- function(obj, .envir = parent.frame()) {
  do.call("return", args = list(obj), envir = .envir)
}


regex_match <- function(text, pattern, i = NULL, ...) {
  match <- regmatches(text, regexec(pattern, text, ...))
  if (!is.null(i)) {
    match <- vapply(match, FUN.VALUE = character(1), function(x) {
      if (length(x) >= i) x[[i]] else NA_character_
    })
  }
  match
}


drop_na <- function(x) {
  x[!is.na(x)]
}


get_photon_version <- function() PHOTON_VERSION


is_url <- function(url) {
  grepl(
    "^(https?:\\/\\/)?[[:alnum:]\\.]+(\\.[[:lower:]]+)|(:[[:digit:]])\\/?",
    url,
    perl = TRUE
  )
}
