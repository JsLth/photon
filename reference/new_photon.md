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
  region = NULL,
  opensearch = TRUE,
  mount = TRUE,
  overwrite = FALSE,
  quiet = FALSE,
  country = NULL
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

- region:

  Character string that identifies a region or country. An extract for
  this region will be downloaded. If `"planet"`, downloads a global
  extract (see note). Run
  [`list_regions()`](https://jslth.github.io/photon/reference/download_database.md)
  to get an overview of available regions. You can specify countries
  using any code that can be translated by
  [`countrycode`](https://vincentarelbundock.github.io/countrycode/man/countrycode.html).

- opensearch:

  Deprecated for photon versions \>= 1.0.0 and superseded for photon
  versions \>= 0.7.0. If `TRUE`, attempts to download the OpenSearch
  version of photon. OpenSearch-based photon supports structured
  geocoding. If `FALSE`, falls back to ElasticSearch. Since photon
  0.7.0, OpenSearch is the default and since 1.0.0, ElasticSearch is not
  supported anymore.

- mount:

  If `TRUE`, mounts the object to the session so that functions like
  [`geocode`](https://jslth.github.io/photon/reference/geocode.md)
  automatically detect the new instance. If `FALSE`, initializes the
  instance but doesn't mount it to the session. Defaults to `TRUE`.

- overwrite:

  If `TRUE`, overwrites existing jar files and search indices when
  initializing a new instance. Defaults to `FALSE`.

- quiet:

  If `TRUE`, suppresses all informative messages.

- country:

  Deprecated since photon 1.0.0. Use `region` instead.

## Value

An R6 object of class `photon`.

## Examples

``` r
if (FALSE) { # getFromNamespace("is_online", "photon")("graphhopper.com") && getFromNamespace("photon_run_examples", "photon")()
# connect to public API
photon <- new_photon()

# connect to arbitrary server
photon <- new_photon(url = "https://photonserver.org")

if (has_java("11")) {
  # set up a local instance in a temporary directory
  dir <- file.path(tempdir(), "photon")
  photon <- new_photon(dir, region = "Andorra")
  photon$purge(ask = FALSE)
}
}
```
