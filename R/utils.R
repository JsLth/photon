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
  grepl(
    "^(https?:\\/\\/)?[[:alnum:]\\.]+(\\.[[:lower:]]+)|(:[[:digit:]])\\/?",
    url,
    perl = TRUE
  )
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
