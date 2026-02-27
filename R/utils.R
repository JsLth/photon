"%||%" <- function(x, y) {
  if (is.null(x)) y else x
}


"%|||%" <- function(x, y) {
  if (is.null(x) || all(is.na(x))) y else x
}


ph_stop <- function(msg, env = parent.frame(), class = NULL, ...) {
  cli::cli_abort(msg, .envir = env, class = c(class, "ph_error"), ...)
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


drop_null <- function(x) {
  if (length(x) == 0 || !is.list(x)) return(x)
  x[!unlist(lapply(x, is.null))]
}


get_latest_photon <- function() {
  PHOTON_VERSION
}


is_url <- function(url) {
  tryCatch({
    httr2::url_parse(url)
    TRUE
  }, error = function(e) FALSE)
}


loadable <- function(x) {
  suppressPackageStartupMessages(requireNamespace(x, quietly = TRUE))
}


as_data_frame <- function(x) {
  if (loadable("tibble")) {
    tibble::as_tibble(x)
  } else {
    as.data.frame(x)
  }
}


as_sf <- function(x) {
  sf::st_as_sf(as_data_frame(x))
}


yes_no <- function(msg, yes = TRUE, no = FALSE, dflt = NULL, ask = TRUE) { # nocov start
  if (!interactive() || !ask) {
    return(dflt)
  }

  input <- readline(paste0(msg, " (y/N/Cancel) "))

  # If neither yes or no is given as input, try again
  if (!input %in% c("y", "N", "Cancel")) {
    Recall(msg, yes = yes, no = no)
  }

  switch(input, y = yes, N = no, Cancel = cancel())
}


cancel <- function(msg = "Input interrupted.") {
  cli::cli_inform(c("x" = msg))
  invokeRestart("abort")
} # nocov end


rbind_list <- function(args) {
  nam <- lapply(args, names)
  unam <- unique(unlist(nam))
  len <- vapply(args, length, numeric(1))
  out <- vector("list", length(len))
  for (i in seq_along(len)) {
    if (nrow(args[[i]])) {
      nam_diff <- setdiff(unam, nam[[i]])
      if (length(nam_diff)) {
        args[[i]][nam_diff] <- NA
      }
    } else {
      next
    }
  }
  out <- suppressWarnings(do.call(rbind, args))
  rownames(out) <- NULL
  out
}


globally_enabled <- function(x) {
  dflt <- switch(
    x,
    photon_debug = FALSE,
    photon_movers = TRUE,
    photon_setup_warn = FALSE
  )
  isTRUE(getOption(x, dflt))
}


is_numver <- function(x) {
  !is.na(numeric_version(x, strict = FALSE))
}


minimum_version <- function(v1, v2) {
  if (is_numver(v1) && is_numver(v2)) {
    numeric_version(v1) >= numeric_version(v2)
  }
}


group_id <- function(x, groups) {
  if (is.data.frame(x)) {
    ids <- do.call(paste, c(x, sep = "_"))
    match(ids, unique(ids))
  } else {
    match(x, groups)
  }
}


get_encoding <- function(x) {
  enc <- Encoding(x)
  switch(enc, unknown = "", enc)
}


#' Latinization
#' @description
#' Helper tool to transliterate various encodings to latin. Attempts to
#' convert a character vector from its current encoding to \code{"latin1"} and -
#' if it fails - defaults back to the original term. This can be useful
#' for \code{\link{geocode}} and \code{\link{structured}} when attempting to
#' geocode terms containing symbols that photon does not support.
#'
#' @param x A character vector.
#' @param encoding Encoding that the strings in \code{x} should be
#' converted to. If the conversion fails, defaults back to the original
#' encoding. Defaults to \code{"latin1"}.
#'
#' @returns The transliterated vector of the same length as \code{x}. \code{NA}s
#' are avoided.
#'
#' @export
#'
#' @examples
#' # converts fancy apostrophes to normal ones
#' latinize("Luatuanu\u2019u")
#'
#' # does nothing
#' latinize("Berlin")
#'
#' # also does nothing, although it would fail with `iconv`
#' latinize("\u0391\u03b8\u03ae\u03bd\u03b1")
latinize <- function(x, encoding = "latin1") {
  assert_vector(x, type = "character")
  enc <- lapply(x, get_encoding)
  ltn <- .mapply(
    iconv,
    dots = list(x = x, from = enc),
    MoreArgs = list(to = encoding)
  )
  conv <- !is.na(ltn)
  x[conv] <- unlist(ltn[conv])
  x
}


to_title <- function(x) {
  gsub("\\b([[:alpha:]])([[:alpha:]]+)", "\\U\\1\\L\\2", x, perl = TRUE)
}


is_online <- function(host) { # nocov start
  req <- httr2::request(host)
  req <- httr2::req_method(req, "HEAD")
  req <- httr2::req_timeout(req, 5)
  tryCatch({
    resp <- httr2::req_perform(req)
    httr2::resp_status(resp) == 200
  }, error = function(e) FALSE)
} # nocov end


photon_run_examples <- function() {
  isTRUE(as.logical(Sys.getenv("PHOTON_RUN_EXAMPLES", FALSE)))
}


deprecated <- function(what, when, where) {
  if (!is.null(what)) {
    ph_stop(c(
      "{what} is deprecated since v{when}.",
      "i" = where
    ))
  }
}
