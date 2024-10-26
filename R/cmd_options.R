#' Format command line options
#' @description
#' Helper function to format options for command line calls. The function
#' accepts key-value pairs where the parameter name is the name of the option
#' and the parameter value is the value of the option.
#' Arguments are formatted according to the following rules:
#'
#' \itemize{
#'  \item{If a value is \code{TRUE}, add parameter name as flag.}
#'  \item{If a value is \code{FALSE}, do not add parameter name as flag.}
#'  \item{If a value has \code{length(x) > 1}, collapse it as a CSV.}
#'  \item{If a parameter name is missing, take the value as the flag name.}
#'  \item{If a parameter name is given, replace underscores with hyphens.}
#' }
#'
#' @param ... Key-value pairs of command line options.
#' @param use_double_hyphens If \code{TRUE}, uses double hyphens to designate
#' non-abbreviated command line options and single-hyphens to designate
#' abbreviated ones. If \code{FALSE}, always uses single hyphens. Defaults
#' to \code{FALSE} as both Java and photon use single hyphens.
#' @returns A character vector of formatted command line options that can
#' be used as input to \code{\link{system2}} or \code{\link[processx]{run}}.
#'
#' @export
#'
#' @examples
#' # converts R parameters to CMD options
#' opts <- cmd_options(n = 1, w = 5, "127.0.0.1")
#' run("ping", args = opts, error_on_status = FALSE, echo_cmd = TRUE)
#'
#' if (nzchar(Sys.which("docker"))) {
#' # sometimes, it is necessary to use double hyphens
#' opts <- cmd_options("ps", all = TRUE, format = "json", use_double_hyphens = TRUE)
#' run("docker", args = opts, error_on_status = FALSE, echo_cmd = TRUE)
#' }
#'
#' if (FALSE) {
#' # particularly useful together with photon
#' # here we start a photon server with cross-site resource sharing enabled
#' dir <- file.path(tempdir(), "photon")
#' photon <- new_photon(dir, country = "Samoa")
#' photon$start(photon_opts = cmd_options(cors_any = TRUE))
#' }
cmd_options <- function(..., use_double_hyphens = FALSE) {
  args <- drop_null(list(...))

  if (all(!lengths(args))) {
    return(NULL)
  }

  unlist(lapply(seq_along(args), function(i) {
    param <- names(args[i])
    val <- args[[i]]

    # rules:
    # 1. if a value is true, add a flag
    # 2. if a value is not true, do not add a flag
    # 3. if a value has length(x) > 1, collapse it as csv
    # 4. if a parameter name is missing, take the value as flag name
    # 5. if a parameter name is given, replace underscores with hyphens
    if (isTRUE(val)) {
      val <- NULL
    }

    if (isFALSE(val)) {
      return(NULL)
    }

    if (length(val) > 1) {
      val <- paste(val, collapse = ",")
    }

    if (!length(param) || !nzchar(param)) {
      param <- NULL
    } else {
      param <- gsub("_", "-", param, fixed = TRUE)
      param <- sprintf("-%s", param)

      if (use_double_hyphens && nchar(param) > 2) {
        param <- paste0("-", param)
      }
    }

    c(param, val)
  }))
}
