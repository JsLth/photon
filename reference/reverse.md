# Reverse geocoding

Reverse geocode a set of points to retrieve their corresponding place
names. To geocode a place name or an address, see
[unstructured](https://jslth.github.io/photon/reference/geocode.md) or
[structured](https://jslth.github.io/photon/reference/structured.md)
geocoding.

## Usage

``` r
reverse(
  .data,
  radius = NULL,
  limit = 1,
  lang = "en",
  osm_tag = NULL,
  layer = NULL,
  locbias = NULL,
  locbias_scale = NULL,
  zoom = NULL,
  distance_sort = TRUE,
  progress = interactive()
)
```

## Arguments

- .data:

  A dataframe or list with names `lon` and `lat`, or an `sfc` or `sf`
  object containing point geometries.

- radius:

  Numeric specifying the range around the points in `.data` that is used
  for searching.

- limit:

  Number of results to return. A maximum of 50 results can be returned
  for a single search term. Defaults to 1. When more than a single text
  is provided but limit is greater than 1, the results can be uniquely
  linked to the input texts using the `idx` column in the output.

- lang:

  Language of the results. If `"default"`, returns the results in local
  language.

- osm_tag:

  Character string giving an [OSM
  tag](https://wiki.openstreetmap.org/wiki/Tags) to filter the results
  by. See details.

- layer:

  Character string giving a layer to filter the results by. Can be one
  of `"house"`, `"street"`, `"locality"`, `"district"`, `"city"`,
  `"county"`, `"state"`, `"country"`, or `"other"`.

- locbias:

  Numeric vector of length 2 or any object that can be coerced to a
  length-2 numeric vector (e.g. a list or `sfg` object). Specifies a
  location bias for geocoding in the format `c(lon, lat)`. Geocoding
  results are biased towards this point. The radius of the bias is
  controlled through `zoom` and the weight of place prominence through
  `location_bias_scale`.

- locbias_scale:

  Numeric vector specifying the importance of prominence in `locbias`. A
  higher prominence scale gives more weight to important places.
  Possible values range from 0 to 1. Defaults to 0.2.

- zoom:

  Numeric specifying the radius for which the `locbias` is effective.
  Corresponds to the zoom level in OpenStreetMap. The exact relation to
  `locbias` is \\0.25\text{ km} \cdot 2^{(18 - \text{zoom})}\\. Defaults
  to 16.

- distance_sort:

  If `TRUE`, sorts the reverse geocoding results based on the distance
  to the input point. Defaults to `TRUE`.

- progress:

  If `TRUE`, shows a progress bar for longer queries.

## Value

An sf dataframe or tibble containing the following columns:

- `idx`: Internal ID specifying the index of the `texts` parameter.

- `osm_type`: Type of OSM element, one of N (node), W (way), R
  (relation), or P (polygon).

- `osm_id`: OpenStreetMap ID of the matched element.

- `country`: Country of the matched place.

- `city`: City of the matched place.

- `osm_key`: OpenStreetMap key.

- `countrycode`: ISO2 country code.

- `housenumber`: House number, if applicable.

- `postcode`: Post code, if applicable.

- `locality`: Locality, if applicable.

- `street`: Street, if applicable.

- `district`: District name, if applicable.

- `osm_value`: OpenStreetMap tag value.

- `name`: Place name.

- `type`: Layer type as described for the `layer` parameter.

- `extent`: Boundary box of the match.

## Details

Filtering by OpenStreetMap tags follows a distinct syntax explained on
<https://github.com/komoot/photon>. In particular:

- Include places with tag: `key:value`

- Exclude places with tag: `!key:value`

- Include places with tag key: `key`

- Include places with tag value: `:value`

- Exclude places with tag key: `!key`

- Exclude places with tag value: `:!value`

## Examples

``` r
# an instance must be mounted first
photon <- new_photon()

# works with sf objects
sf_data <- sf::st_sfc(sf::st_point(c(8, 52)), sf::st_point(c(7, 52)), crs = 4326)
reverse(sf_data)
#> Simple feature collection with 2 features and 17 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: 6.995134 ymin: 51.99925 xmax: 7.999094 ymax: 52.00153
#> Geodetic CRS:  WGS 84
#> # A tibble: 2 × 18
#>     idx osm_type     osm_id osm_key osm_value   type  postcode countrycode name 
#>   <int> <chr>         <dbl> <chr>   <chr>       <chr> <chr>    <chr>       <chr>
#> 1     1 W          28000939 highway unclassifi… stre… 48336    DE          Gröb…
#> 2     2 N        4210183016 place   house       house 48703    DE          NA   
#> # ℹ 9 more variables: country <chr>, city <chr>, district <chr>, state <chr>,
#> #   county <chr>, extent <list>, housenumber <chr>, street <chr>,
#> #   geometry <POINT [°]>

# ... but also with simple dataframes
df_data <- data.frame(lon = c(8, 7), lat = c(52, 52))
reverse(df_data)
#> Simple feature collection with 2 features and 17 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: 6.995134 ymin: 51.99925 xmax: 7.999094 ymax: 52.00153
#> Geodetic CRS:  WGS 84
#> # A tibble: 2 × 18
#>     idx osm_type     osm_id osm_key osm_value   type  postcode countrycode name 
#>   <int> <chr>         <dbl> <chr>   <chr>       <chr> <chr>    <chr>       <chr>
#> 1     1 W          28000939 highway unclassifi… stre… 48336    DE          Gröb…
#> 2     2 N        4210183016 place   house       house 48703    DE          NA   
#> # ℹ 9 more variables: country <chr>, city <chr>, district <chr>, state <chr>,
#> #   county <chr>, extent <list>, housenumber <chr>, street <chr>,
#> #   geometry <POINT [°]>

# limit search radius to 10m
reverse(df_data, radius = 10)
#> Simple feature collection with 2 features and 17 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: 6.995134 ymin: 51.99925 xmax: 7.999094 ymax: 52.00153
#> Geodetic CRS:  WGS 84
#> # A tibble: 2 × 18
#>     idx osm_type     osm_id osm_key osm_value   type  postcode countrycode name 
#>   <int> <chr>         <dbl> <chr>   <chr>       <chr> <chr>    <chr>       <chr>
#> 1     1 W          28000939 highway unclassifi… stre… 48336    DE          Gröb…
#> 2     2 N        4210183016 place   house       house 48703    DE          NA   
#> # ℹ 9 more variables: country <chr>, city <chr>, district <chr>, state <chr>,
#> #   county <chr>, extent <list>, housenumber <chr>, street <chr>,
#> #   geometry <POINT [°]>
```
