# Format command line options

Helper function to format options for command line calls. The function
accepts key-value pairs where the parameter name is the name of the
option and the parameter value is the value of the option. Arguments are
formatted according to the following rules:

- If a value is `TRUE`, add parameter name as flag.

- If a value is `FALSE`, do not add parameter name as flag.

- If a value has `length(x) > 1`, collapse it as a CSV.

- If a parameter name is missing, take the value as the flag name.

- If a parameter name is given, replace underscores with hyphens.

## Usage

``` r
cmd_options(..., use_double_hyphens = FALSE)
```

## Arguments

- ...:

  Key-value pairs of command line options.

- use_double_hyphens:

  If `TRUE`, uses double hyphens to designate non-abbreviated command
  line options and single-hyphens to designate abbreviated ones. If
  `FALSE`, always uses single hyphens. Defaults to `FALSE` as both Java
  and photon use single hyphens.

## Value

A character vector of formatted command line options that can be used as
input to [`system2`](https://rdrr.io/r/base/system2.html) or
[`run`](http://processx.r-lib.org/reference/run.md).

## Examples

``` r
# converts R parameters to CMD options
# parameters for the ping command
cmd_options(n = 1, w = 5, "127.0.0.1")
#> [1] "-n"        "1"         "-w"        "5"         "127.0.0.1"

# sometimes, it is necessary to use double hyphens
# options for the docker ps command
cmd_options("ps", all = TRUE, format = "json", use_double_hyphens = TRUE)
#> [1] "ps"       "--all"    "--format" "json"    

# particularly useful together with photon
# the following options can be used for the `photon_opts` argument
# of photon$start()
cmd_options(cors_any = TRUE, data_dir = "path/to/dir")
#> [1] "-cors-any"   "-data-dir"   "path/to/dir"
```
