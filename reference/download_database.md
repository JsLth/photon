# Download search index

Finds and downloads the OpenSearch index database necessary to set up
Photon locally.

`list_regions` returns an overview of regions and countries that are
valid to pass to the `region` argument.

## Usage

``` r
download_database(
  region,
  path = tempdir(),
  version = get_latest_photon(),
  json = FALSE,
  only_url = FALSE,
  quiet = FALSE,
  country = NULL
)

list_regions(region = NULL)
```

## Arguments

- region:

  Character string that identifies a region or country. An extract for
  this region will be downloaded. If `"planet"`, downloads a global
  extract (see note). Run `list_regions()` to get an overview of
  available regions. You can specify countries using any code that can
  be translated by
  [`countrycode`](https://vincentarelbundock.github.io/countrycode/man/countrycode.html).

- path:

  Path to a directory where the identified file should be stored.
  Defaults to [`tempdir()`](https://rdrr.io/r/base/tempfile.html).

- version:

  Photon version that the database should be used with. Defaults to the
  latest version known to the package (1.0.0). Can also be `"master"`,
  which is probably based on the master branch of photon.

- json:

  Extracts come in two forms: JSON dumps and pre-build databases.
  Pre-built databases are more convenient but less flexible and are not
  available for all regions. If you wish or need to build your own
  database, set `json = TRUE` and use the `$import()` method (see
  [`photon_local`](https://jslth.github.io/photon/reference/photon_local.md)).

- only_url:

  If `TRUE`, performs a download. Otherwise, only returns a link to the
  file.

- quiet:

  If `TRUE`, suppresses all informative messages.

- country:

  Deprecated since photon 1.0.0. Use `region` instead.

## Value

If `only_url = FALSE`, returns the local path to the downloaded file.
Otherwise, returns the URL to the remote file.

## Note

Depending on the region, search index databases tend to be very large.
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
from region extracts. If you need a more fine-grained scope or a
combination of multiple countries, you need to build your own search
index. See
[`vignette("nominatim-import", package = "photon")`](https://jslth.github.io/photon/articles/nominatim-import.md).

## Examples

``` r
if (FALSE) { # getFromNamespace("is_online", "photon")("graphhopper.com") && getFromNamespace("photon_run_examples", "photon")()
# check available regions in Europe first
list_regions("europe")

# download the latest database of Andorra
download_database("Andorra")

# if you need to build your own search index, you can download a JSON dump
# this might also be necessary if no pre-built database dump exists
download_database("Andorra", json = TRUE)

# get the latest global coverage
# NOTE: the file to be downloaded is several tens of gigabytes of size!
if (FALSE) { # \dontrun{
download_database("planet")} # }
}
```
