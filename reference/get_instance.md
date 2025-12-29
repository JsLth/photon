# Photon utilities

Utilities to manage photon instances. These functions operate on mounted
photon instances which can be initialized using
[`new_photon`](https://jslth.github.io/photon/reference/new_photon.md).

- `get_instance()` retrieves the active photon instance.

- `get_photon_url()` retrieves the photon URL to send requests.

## Usage

``` r
get_instance()

get_photon_url()
```

## Value

`get_instance` returns a R6 object of class `photon`. `get_photon_url()`
returns a URL string.

## Examples

``` r
# make a new photon instance
new_photon()
#> <photon>
#>   Type   : remote
#>   Server : https://photon.komoot.io/

# retrieve it from the cache
get_instance()
#> <photon>
#>   Type   : remote
#>   Server : https://photon.komoot.io/

# get the server url
get_photon_url()
#> [1] "https://photon.komoot.io/"
```
