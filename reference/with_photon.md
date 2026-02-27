# Local photon instances

Evaluate R code with a photon instance without changing the active
photon mount.

## Usage

``` r
with_photon(photon, code)
```

## Arguments

- photon:

  An object of class
  [`photon`](https://jslth.github.io/photon/reference/new_photon.md)
  that is temporarily mounted to the session.

- code:

  Code to execute in the temporary environment.

## Value

The results of the evaluation of the `code` argument.

## Examples

``` r
# Get a public instance
pub_photon <- new_photon()

# Mount a custom instance
new_photon(url = "https://localhost:8001/")
#> <photon>
#>   Type   : remote
#>   Server : https://localhost:8001/

# Geocode with the public instance only once
with_photon(pub_photon, geocode("Rutland"))
#> Simple feature collection with 1 feature and 10 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: 97.74531 ymin: 64.68631 xmax: 97.74531 ymax: 64.68631
#> Geodetic CRS:  WGS 84
#> # A tibble: 1 × 11
#>     idx osm_type osm_id osm_key osm_value type  countrycode name  country extent
#>   <int> <chr>     <int> <chr>   <chr>     <chr> <chr>       <chr> <chr>   <list>
#> 1     1 R         60189 place   country   coun… RU          Russ… Russia  <dbl> 
#> # ℹ 1 more variable: geometry <POINT [°]>

# The custom instance is still mounted
get_instance()
#> <photon>
#>   Type   : remote
#>   Server : https://localhost:8001/
```
