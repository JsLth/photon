# Download search index

Finds and downloads the OpenSearch index database necessary to set up
Photon locally.

## Usage

``` r
download_searchindex(
  country,
  path = tempdir(),
  date = "latest",
  exact = FALSE,
  section = NULL,
  only_url = FALSE,
  quiet = FALSE
)
```

## Arguments

- country:

  Character string that can be identified by
  [`countryname`](https://vincentarelbundock.github.io/countrycode/reference/countryname.html)
  as a country. An extract for this country will be downloaded. If
  `"planet"`, downloads a global search index (see note).

- path:

  Path to a directory where the identified file should be stored.
  Defaults to [`tempdir()`](https://rdrr.io/r/base/tempfile.html).

- date:

  Character string or date-time object used to specify the creation date
  of the search index. If `"latest"`, will download the file tagged with
  "latest". If a character string, the value should be parseable by
  [`as.POSIXct`](https://rdrr.io/r/base/as.POSIXlt.html). If
  `exact = FALSE`, the input value is compared to all available dates
  and the closest date will be selected. Otherwise, a file will be
  selected that exactly matches the input to `date`.

- exact:

  If `TRUE`, exactly matches the `date`. Otherwise, selects the date
  with lowest difference to the `date` parameter.

- section:

  Subdirectory of the download server from which to select a search
  index. If `"experimental"`, selects a dump made for the master version
  of photon. If `"archived"`, selects a dump made for an older version
  of photon. If `NULL` (or any arbitrary string), selects a dump made
  for the current release. Defaults to `NULL`.

- only_url:

  If `TRUE`, performs a download. Otherwise, only returns a link to the
  file.

- quiet:

  If `TRUE`, suppresses all informative messages.

## Value

If `only_url = FALSE`, returns the local path to the downloaded file.
Otherwise, returns the URL to the remote file.

## Note

Depending on the country, search index databases tend to be very large.
The global search index is about 75 GB of size (10/2024). Keep that in
mind when running this function.

## Limitations

The index download depends on a public repository
(<https://download1.graphhopper.com/public/>). This repository only
hosts search indices for the latest stable and experimental versions and
is thus not suitable for reproducibility. If you wish to make a project
reproducible, consider storing the search index somewhere persistent.
Photon is generally not backwards-compatible and newer versions of
Photon are not guaranteed to work with older search indices (based on
personal experience).

Additionally, this function can only download pre-built search indices
from country extracts. If you need a more fine-grained scope or a
combination of multiple countries, you need to build your own search
index. See
[`vignette("nominatim-import", package = "photon")`](https://jslth.github.io/photon/articles/nominatim-import.md).

## Examples

``` r
# download the latest extract of Monaco
download_searchindex("Monaco", path = tempdir())
#> ℹ Fetching search index for Monaco, created on latest
#> ✔ Successfully downloaded search index. [1.8s]
#> 
#> [1] "/tmp/Rtmp97w4wR/photon-db-mc-latest.tar.bz2"

# download the latest extract of American Samoa
download_searchindex(path = tempdir(), section = NULL, country = "Samoa")
#> ℹ Fetching search index for Samoa, created on latest
#> ✔ Successfully downloaded search index. [336ms]
#> 
#> [1] "/tmp/Rtmp97w4wR/photon-db-ws-latest.tar.bz2"

# download an extract from a month ago
try(download_searchindex(
  path = tempdir(),
  country = "Monaco",
  date = Sys.time() - 2629800
))
#> ℹ Fetching search index for Monaco, created on 2025-07-20
#> ✔ Successfully downloaded search index. [184ms]
#> 
#> [1] "/tmp/Rtmp97w4wR/photon-db-mc-250720.tar.bz2"

# if possible, download an extract from today
try(download_searchindex(
  path = tempdir(),
  country = "Monaco",
  date = Sys.Date(),
  exact = TRUE
))
#> Error in download_searchindex(path = tempdir(), country = "Monaco", date = Sys.Date(),  : 
#>   ! Specified `date` does not match any available dates.
#> ℹ Consider setting `exact = FALSE`.

# get the latest global coverage
# NOTE: the file to be downloaded is several tens of gigabytes of size!
if (FALSE) { # \dontrun{
download_searchindex(path = tempdir(), country = "planet")} # }
```
