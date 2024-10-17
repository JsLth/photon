ignore_null <- function() {
  args <- parent.frame()
  if (is.null(args$x) && isTRUE(args$null)) {
    return_from_parent(NULL, .envir = parent.frame())
  }
}

assert_length <- function(x, len = 1, null = FALSE) {
  ignore_null()
  cond <- length(x) == len
  if (!cond) {
    var <- deparse(substitute(x))
    ph_stop("{.code {var}} must have length {.field {len}}, not {.field {length(x)}}.")
  }
}


assert_vector <- function(x, type, null = FALSE) {
  ignore_null()
  cond <- is.atomic(x) && typeof(x) == type
  if (!cond) {
    var <- deparse(substitute(x))
    ph_stop("{.code {var}} must be an atomic vector of type {.cls {type}}, not {.cls {typeof(x)}}.")
  }
}


assert_true_or_false <- function(x, null = FALSE) {
  ignore_null()
  cond <- is.logical(x) && !is.na(x)
  if (!cond) {
    var <- deparse(substitute(x))
    ph_stop("{.code {var}} must be a vector consisting only of TRUE or FALSE.")
  }
}


assert_dir <- function(x, null = FALSE, must_exist = FALSE) {
  ignore_null()
  cond <- is.character(x) && file.exists(x) && file.info(x)$isdir
  if (!cond) {
    var <- deparse(substitute(x))
    ph_stop("{.code {var}} must be a valid path to an existing directory.")
  }
}


assert_url <- function(x, null = FALSE) {
  ignore_null()
  cond <- is.character(x) && is_url(x)
  if (!cond) {
    var <- deparse(substitute(x))
    ph_stop("{.code {var}} must be a valid URL.")
  }
}


assert_class <- function(x, class, null = FALSE) {
  ignore_null()
  cond <- inherits(x, class)
  if (!cond) {
    var <- deparse(substitute(x))
    ph_stop("{.code {var}} must be a of class {.cls {class}}, not {.cls {class(x)}}.")
  }
}


assert_named <- function(x, names, null = FALSE) {
  ignore_null()
  cond <- names(x) %in% names
  if (!cond) {
    var <- deparse(substitute(x))
    names <- cli::cli_vec(names, style = list("vec-last" = ", "))
    ph_stop("{.code {var}} must contain at least one of the following names: {.val {names}}")
  }
}
