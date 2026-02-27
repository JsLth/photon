# Structured geocoding

Geocode a set of place information such as street, house number, or post
code. Structured geocoding is generally more accurate but requires more
information than [unstructured
geocoding](https://jslth.github.io/photon/reference/geocode.md).

You can use the helper function `has_structured_support()` to check if
the current API supports structured geocoding. Structured geocoding
should be enabled on the public photon instance and all photon instances
\>= 1.0.0, but older versions usually have structured queries disabled.

## Usage

``` r
structured(
  .data,
  limit = 1,
  lang = "en",
  bbox = NULL,
  osm_tag = NULL,
  layer = NULL,
  locbias = NULL,
  locbias_scale = NULL,
  zoom = NULL,
  dedupe = TRUE,
  include = NULL,
  exclude = NULL,
  progress = interactive()
)

has_structured_support()
```

## Arguments

- .data:

  Dataframe or list containing structured information on a place to
  geocode. Can contain the columns `street`, `housenumber`, `postcode`,
  `city`, `district`, `county`, `state`, and `countrycode`. At least one
  of these columns must be present in the dataframe. Note that countries
  must be passed as ISO-2 country codes.

- limit:

  Number of results to return. A maximum of 50 results can be returned
  for a single search term. Defaults to 1. When more than a single text
  is provided but limit is greater than 1, the results can be uniquely
  linked to the input texts using the `idx` column in the output.

- lang:

  Language of the results. If `"default"`, returns the results in local
  language.

- bbox:

  Any object that can be parsed by
  [`st_bbox`](https://r-spatial.github.io/sf/reference/st_bbox.html).
  Results must lie within this bbox.

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

- dedupe:

  If `FALSE`, keeps duplicates in the geocoding results. By default,
  photon attempts to deduplicate results that have the same name,
  postcode, and OSM value. Defaults to `TRUE`.

- include, exclude:

  Character vector containing
  [categories](https://github.com/komoot/photon/blob/master/docs/categories.md)
  to include or exclude. Places will be *included* if any category in
  `include` is present. Places will be *excluded* if all categories in
  `exclude` are present.

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
# \donttest{
# check if structured() is supported
has_structured_support()
#> [1] TRUE

# structured() works on dataframes containing structurized data
place_data <- data.frame(
  housenumber = c(NA, "77C", NA),
  street = c("Falealilli Cross Island Road", "Main Beach Road", "Le Mafa Pass Road"),
  state = c("Tuamasaga", "Tuamasaga", "Atua")
)
structured(place_data, limit = 1)
#> Simple feature collection with 3 features and 14 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: -171.7762 ymin: -14.00997 xmax: -171.5835 ymax: -13.83381
#> Geodetic CRS:  WGS 84
#> # A tibble: 3 × 15
#>     idx osm_type    osm_id osm_key osm_value type  countrycode name  city  state
#>   <int> <chr>        <int> <chr>   <chr>     <chr> <chr>       <chr> <chr> <chr>
#> 1     1 W        107470604 highway primary   stre… WS          Fale… Tiap… Tuam…
#> 2     2 W        569855981 amenity police    house WS          Poli… Apia  Tuam…
#> 3     3 W        141654556 highway primary   stre… WS          Le M… NA    Ātua 
#> # ℹ 5 more variables: country <chr>, extent <list>, housenumber <chr>,
#> #   street <chr>, geometry <POINT [°]>

# countries must be specified as iso2 country codes
structured(data.frame(countrycode = "ws"))
#> Simple feature collection with 1 feature and 10 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: -172.12 ymin: -13.76939 xmax: -172.12 ymax: -13.76939
#> Geodetic CRS:  WGS 84
#> # A tibble: 1 × 11
#>     idx osm_type osm_id osm_key osm_value type  countrycode name  country extent
#>   <int> <chr>     <int> <chr>   <chr>     <chr> <chr>       <chr> <chr>   <list>
#> 1     1 R        1.87e6 place   country   coun… WS          Sāmoa Samoa   <dbl> 
#> # ℹ 1 more variable: geometry <POINT [°]>

# traditional parameters from geocode() can also be used but are much more niche
structured(data.frame(city = "Apia"), layer = "house") # matches nothing
#> Simple feature collection with 1 feature and 10 fields (with 1 geometry empty)
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: Inf ymin: Inf xmax: -Inf ymax: -Inf
#> Geodetic CRS:  WGS 84
#> # A tibble: 1 × 11
#>     idx osm_type osm_id country osm_key countrycode osm_value name  type  extent
#>   <int> <chr>     <int> <chr>   <chr>   <chr>       <chr>     <chr> <chr> <list>
#> 1     1 NA           NA NA      NA      NA          NA        NA    NA    <dbl> 
#> # ℹ 1 more variable: geometry <POINT [°]>

# structured geocoding can discern small differences in places
safune <- data.frame(
  city = c("Berlin", "Berlin"),
  countrycode = c("DE", "US")
)
structured(safune, limit = 1)
#> Simple feature collection with 2 features and 12 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: -88.94662 ymin: 43.96843 xmax: 13.78453 ymax: 52.47129
#> Geodetic CRS:  WGS 84
#> # A tibble: 2 × 13
#>     idx osm_type  osm_id osm_key osm_value type  countrycode name   county state
#>   <int> <chr>      <int> <chr>   <chr>     <chr> <chr>       <chr>  <chr>  <chr>
#> 1     1 R        1332927 place   village   city  DE          Rüder… Märki… Bran…
#> 2     2 R         251729 place   town      city  US          City … Green… Wisc…
#> # ℹ 3 more variables: country <chr>, extent <list>, geometry <POINT [°]>
# }
```
