# Download photon

Download the photon executable from GitHub.

## Usage

``` r
download_photon(
  path = tempdir(),
  version = NULL,
  opensearch = TRUE,
  only_url = FALSE,
  quiet = FALSE
)
```

## Arguments

- path:

  Path to a directory to store the executable. Defaults to
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html).

- version:

  Version tag of the photon release. If `NULL`, downloads the latest
  known version (1.0.0). A list of all releases can be found here:
  <https://github.com/komoot/photon/releases/>. Ignored if `jar` is
  given.

- opensearch:

  If `TRUE`, downloads the OpenSearch version of photon if available.
  OpenSearch versions are available for photon \>= 0.6.0. Since photon
  \>= 0.7.0, OpenSearch versions are recommended. Defaults to `TRUE`.

- only_url:

  If `TRUE`, performs a download. Otherwise, only returns a link to the
  file.

- quiet:

  If `TRUE`, suppresses all informative messages.

## Value

If `only_url = FALSE`, returns a character string giving the path to the
downloaded file. Otherwise, returns the URL to be downloaded.

## Examples

``` r
download_photon(tempdir(), version = "0.4.1", opensearch = FALSE)
#> ℹ Fetching ElasticSearch photon 0.4.1.
#> ✔ Successfully downloaded ElasticSearch photon 0.4.1. [1s]
#> 
#> [1] "/tmp/Rtmph9n2dC/photon-0.4.1.jar"
```
