# Initialize a photon instance

Initialize a photon instance by creating a new photon object. This
object is stored in the R session and can be used to perform geocoding
requests.

Instances can either be local or remote. Remote instances require
nothing more than a URL that geocoding requests are sent to. Local
instances require the setup of the photon executable, a search index,
and Java. See
[`photon_local`](https://jslth.github.io/photon/reference/photon_local.md)
for details.

## Usage

``` r
new_photon(
  path = NULL,
  url = NULL,
  photon_version = NULL,
  country = NULL,
  date = "latest",
  exact = FALSE,
  section = NULL,
  opensearch = TRUE,
  mount = TRUE,
  overwrite = FALSE,
  quiet = FALSE
)
```

## Arguments

- path:

  Path to a directory where the photon executable and data should be
  stored. Defaults to a directory "photon" in the current working
  directory. If `NULL`, a remote instance is set up based on the `url`
  parameter.

- url:

  URL of a photon server to connect to. If `NULL` and `path` is also
  `NULL`, connects to the public API under <https://photon.komoot.io/>.

- photon_version:

  Version of photon to be used. A list of all releases can be found
  here: <https://github.com/komoot/photon/releases/>. Ignored if `jar`
  is given. If `NULL`, uses the latest known version.

- country:

  Character string that can be identified by
  [`countryname`](https://vincentarelbundock.github.io/countrycode/reference/countryname.html)
  as a country. An extract for this country will be downloaded. If
  `"planet"`, downloads a global search index. If `NULL`, downloads no
  index and leaves download or import to the user.

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

- opensearch:

  If `TRUE`, attempts to download the OpenSearch version of photon.
  OpenSearch-based photon supports structrued geocoding. Readily
  available OpenSearch photon executables are only offered since photon
  version 0.6.0. For earlier versions, you need to build it from source
  using gradle. In this case, if `TRUE`, will look for an OpenSearch
  version of photon in the specified path. Since photon version 0.7.0,
  OpenSearch is the recommended option. Defaults to `TRUE`.

- mount:

  If `TRUE`, mounts the object to the session so that functions like
  [`geocode`](https://jslth.github.io/photon/reference/geocode.md)
  automatically detect the new instance. If `FALSE`, initializies the
  instance but doesn't mount it to the session. Defaults to `TRUE`.

- overwrite:

  If `TRUE`, overwrites existing jar files and search indices when
  initializing a new instance. Defaults to `FALSE`.

- quiet:

  If `TRUE`, suppresses all informative messages.

## Value

An R6 object of class `photon`.

## Examples

``` r
# connect to public API
photon <- new_photon()

# connect to arbitrary server
photon <- new_photon(url = "https://photonserver.org")

if (has_java("11")) {
# set up a local instance in a temporary directory
dir <- file.path(tempdir(), "photon")
photon <- new_photon(dir, country = "Monaco")
}
#> ℹ openjdk version "17.0.17" 2025-10-21
#> ℹ OpenJDK Runtime Environment Temurin-17.0.17+10 (build 17.0.17+10)
#> ℹ OpenJDK 64-Bit Server VM Temurin-17.0.17+10 (build 17.0.17+10, mixed mode,
#>   sharing)
#> ℹ Fetching OpenSearch photon 0.7.4.
#> ✔ Successfully downloaded OpenSearch photon 0.7.4. [1.6s]
#> 
#> ℹ Fetching search index for Monaco, created on latest
#> ✔ Successfully downloaded search index. [1.1s]
#> 
#> • Version: 0.7.4
#> • Coverage: Monaco
#> • Time: 2025-12-29

photon$purge(ask = FALSE)
```
