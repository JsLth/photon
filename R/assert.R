ignore_null <- function() {
  args <- parent.frame()
  if (is.null(args$x) && isTRUE(args$null)) {
    return_from_parent(NULL, .envir = parent.frame())
  }
}


get_caller_name <- function(parent = sys.parent()) {
  deparse(sys.call(parent)[[1]])
}


varname <- function(x, env = parent.frame()) {
  deparse(substitute(x, env))
}


assert_vector <- function(x,
                          type = NULL,
                          size = NULL,
                          null = FALSE,
                          na = FALSE,
                          name = varname(x)) {
  ignore_null()
  if (!na) assert_na(x, name = name)
  ttype <- mode(x)
  cond <- is.atomic(x) && ttype %in% type
  if (!is.null(type) && !cond) {
    ph_stop(
      "{.code {name}} must be an atomic vector of type {.cls {type}}, not {.cls {ttype}}.",
      class = get_caller_name()
    )
  }

  cond <- length(x) == size
  if (!is.null(size) && !cond) {
    ph_stop(
      "{.code {name}} must be an atomic vector of size {size}, not {length(x)}.",
      class = get_caller_name()
    )
  }
}


assert_flag <- function(x, null = FALSE, name = varname(x)) {
  ignore_null()
  assert_vector(x, size = 1, na = TRUE, name = name)
  cond <- is.logical(x) && !is.na(x)
  if (!cond) {
    ph_stop(
      "{.code {name}} must be a vector consisting only of TRUE or FALSE.",
      class = get_caller_name()
    )
  }
}


assert_dir <- function(x, null = FALSE, name = varname(x)) {
  ignore_null()
  assert_vector(x, type = "character", size = 1, name = name)
  cond <- file.exists(x) && file.info(x)$isdir
  if (!cond) {
    ph_stop(
      "{.code {name}} must be a valid path to an existing directory.",
      class = get_caller_name()
    )
  }
}


assert_url <- function(x, null = FALSE, name = varname(x)) {
  ignore_null()
  assert_vector(x, "character", size = 1, name = name)
  cond <- is_url(x)
  if (!cond) {
    ph_stop(
      "{.code {name}} must be a valid URL.",
      class = get_caller_name()
    )
  }
}


assert_class <- function(x, class, null = FALSE, name = varname(x)) {
  ignore_null()
  cond <- inherits(x, class)
  if (!cond) {
    ph_stop(
      "{.code {name}} must be a of class {.cls {class}}, not {.cls {class(x)}}.",
      class = get_caller_name()
    )
  }
}


assert_named <- function(x, names, all = FALSE, null = FALSE, name = varname(x)) {
  ignore_null()
  cond <- if (all) {
    all(names(x) %in% names)
  } else {
    any(names(x) %in% names)
  }
  if (!cond) {
    names <- cli::cli_vec(names, style = list("vec-last" = ", "))
    ph_stop(
      "{.code name}} must contain at least one of the following names: {.val {names}}",
      class = get_caller_name()
    )
  }
}


assert_range <- function(x, min, max, than = TRUE, name = varname(x)) {
  ignore_null()
  assert_na(x, name = name)
  cond <- if (than) {
    all(x > min, x < max)
  } else {
    all(x >= min, x <= max)
  }
  if (!cond) {
    ph_stop(
      paste(
        "{.code {name}} must be greater than {min} and lower than {max},",
        "got {.field {x}} instead."
      ),
      class = get_caller_name()
    )
  }
}


assert_na <- function(x, name = varname(x)) {
  cond <- is.na(x)
  if (any(cond)) {
    ph_stop(
      "{.code {name}} must not contain missing values.",
      class = get_caller_name()
    )
  }
}
