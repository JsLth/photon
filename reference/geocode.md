# Unstructured geocoding

Geocode arbitrary text strings. Unstructured geocoding is more flexible
but generally less accurate than [structured
geocoding](https://jslth.github.io/photon/reference/structured.md).

## Usage

``` r
geocode(
  texts,
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
  latinize = TRUE,
  progress = interactive()
)
```

## Arguments

- texts:

  Character vector of a texts to geocode.

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

- latinize:

  If `TRUE` sanitizes search terms in `texts` by converting their
  encoding to `"latin1"` using
  [`latinize`](https://jslth.github.io/photon/reference/latinize.md).
  This can be helpful if the search terms contain certain symbols (e.g.
  fancy quotes) that photon cannot handle properly. Defaults to `TRUE`
  as `latinize` is very conservative and should usually not cause any
  problems.

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

# geocode a city
geocode("Berlin")
#> Simple feature collection with 1 feature and 10 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: 13.39513 ymin: 52.51739 xmax: 13.39513 ymax: 52.51739
#> Geodetic CRS:  WGS 84
#> # A tibble: 1 × 11
#>     idx osm_type osm_id osm_key osm_value type  countrycode name  country extent
#>   <int> <chr>     <int> <chr>   <chr>     <chr> <chr>       <chr> <chr>   <list>
#> 1     1 R         62422 place   city      city  DE          Berl… Germany <dbl> 
#> # ℹ 1 more variable: geometry <POINT [°]>

# return more results
geocode("Berlin", limit = 10)
#> Simple feature collection with 10 features and 18 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: -89.90316 ymin: 39.75894 xmax: 13.39513 ymax: 52.53406
#> Geodetic CRS:  WGS 84
#> # A tibble: 10 × 19
#>      idx osm_type      osm_id osm_key  osm_value  type  postcode housenumber
#>    <int> <chr>          <dbl> <chr>    <chr>      <chr> <chr>    <chr>      
#>  1     1 R              62422 place    city       city  NA       NA         
#>  2     1 R            1152723 place    village    city  57370    NA         
#>  3     1 N        13277221839 historic citywalls  house 13355    NA         
#>  4     1 N        13456118964 tourism  artwork    house 10117    NA         
#>  5     1 N        13456106083 tourism  artwork    house 10117    NA         
#>  6     1 R             170184 place    city       city  03570    NA         
#>  7     1 W           38862723 leisure  stadium    house 14053    3          
#>  8     1 R           14720811 amenity  university house 10719    NA         
#>  9     1 R           11042445 place    town       city  NA       NA         
#> 10     1 R             126290 place    village    city  NA       NA         
#> # ℹ 11 more variables: countrycode <chr>, name <chr>, county <chr>,
#> #   state <chr>, street <chr>, locality <chr>, district <chr>, city <chr>,
#> #   country <chr>, extent <list>, geometry <POINT [°]>

# return the results in german
geocode("Berlin", limit = 10, lang = "de")
#> Simple feature collection with 10 features and 18 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: -89.90316 ymin: 39.75894 xmax: 13.39513 ymax: 52.53406
#> Geodetic CRS:  WGS 84
#> # A tibble: 10 × 19
#>      idx osm_type      osm_id osm_key  osm_value  type  postcode housenumber
#>    <int> <chr>          <dbl> <chr>    <chr>      <chr> <chr>    <chr>      
#>  1     1 R              62422 place    city       city  NA       NA         
#>  2     1 R            1152723 place    village    city  57370    NA         
#>  3     1 N        13277221839 historic citywalls  house 13355    NA         
#>  4     1 N        13456118964 tourism  artwork    house 10117    NA         
#>  5     1 N        13456106083 tourism  artwork    house 10117    NA         
#>  6     1 R             170184 place    city       city  03570    NA         
#>  7     1 W           38862723 leisure  stadium    house 14053    3          
#>  8     1 R           14720811 amenity  university house 10719    NA         
#>  9     1 R           11042445 place    town       city  NA       NA         
#> 10     1 R             126290 place    village    city  NA       NA         
#> # ℹ 11 more variables: countrycode <chr>, name <chr>, county <chr>,
#> #   state <chr>, street <chr>, locality <chr>, district <chr>, city <chr>,
#> #   country <chr>, extent <list>, geometry <POINT [°]>

# limit to cities
geocode("Berlin", layer = "city")
#> Simple feature collection with 1 feature and 10 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: 13.39513 ymin: 52.51739 xmax: 13.39513 ymax: 52.51739
#> Geodetic CRS:  WGS 84
#> # A tibble: 1 × 11
#>     idx osm_type osm_id osm_key osm_value type  countrycode name  country extent
#>   <int> <chr>     <int> <chr>   <chr>     <chr> <chr>       <chr> <chr>   <list>
#> 1     1 R         62422 place   city      city  DE          Berl… Germany <dbl> 
#> # ℹ 1 more variable: geometry <POINT [°]>

# limit to European cities
geocode("Berlin", bbox = c(xmin = -71.18, ymin = 44.46, xmax = 13.39, ymax = 52.52))
#> Simple feature collection with 1 feature and 13 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: 7.241838 ymin: 48.80095 xmax: 7.241838 ymax: 48.80095
#> Geodetic CRS:  WGS 84
#> # A tibble: 1 × 14
#>     idx osm_type  osm_id osm_key osm_value type  postcode countrycode name   
#>   <int> <chr>      <int> <chr>   <chr>     <chr> <chr>    <chr>       <chr>  
#> 1     1 R        1152723 place   village   city  57370    FR          Berling
#> # ℹ 5 more variables: county <chr>, state <chr>, country <chr>, extent <list>,
#> #   geometry <POINT [°]>

# search for museums in berlin
geocode("Berlin", osm_tag = "tourism:museum")
#> Simple feature collection with 1 feature and 16 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: 13.39823 ymin: 52.50391 xmax: 13.39823 ymax: 52.50391
#> Geodetic CRS:  WGS 84
#> # A tibble: 1 × 17
#>     idx osm_type osm_id osm_key osm_value type  postcode housenumber countrycode
#>   <int> <chr>     <int> <chr>   <chr>     <chr> <chr>    <chr>       <chr>      
#> 1     1 W        3.37e7 tourism museum    house 10969    124-128     DE         
#> # ℹ 8 more variables: name <chr>, street <chr>, locality <chr>, district <chr>,
#> #   city <chr>, country <chr>, extent <list>, geometry <POINT [°]>

# search for touristic attractions in berlin
geocode("Berlin", osm_tag = "tourism")
#> Simple feature collection with 1 feature and 14 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: 13.37353 ymin: 52.52413 xmax: 13.37353 ymax: 52.52413
#> Geodetic CRS:  WGS 84
#> # A tibble: 1 × 15
#>     idx osm_type      osm_id osm_key osm_value type  postcode countrycode name  
#>   <int> <chr>          <dbl> <chr>   <chr>     <chr> <chr>    <chr>       <chr> 
#> 1     1 N        13456118964 tourism artwork   house 10117    DE          Berli…
#> # ℹ 6 more variables: street <chr>, locality <chr>, district <chr>, city <chr>,
#> #   country <chr>, geometry <POINT [°]>

# search for anything but tourism
geocode("Berlin", osm_tag = "!tourism")
#> Simple feature collection with 1 feature and 10 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: 13.39513 ymin: 52.51739 xmax: 13.39513 ymax: 52.51739
#> Geodetic CRS:  WGS 84
#> # A tibble: 1 × 11
#>     idx osm_type osm_id osm_key osm_value type  countrycode name  country extent
#>   <int> <chr>     <int> <chr>   <chr>     <chr> <chr>       <chr> <chr>   <list>
#> 1     1 R         62422 place   city      city  DE          Berl… Germany <dbl> 
#> # ℹ 1 more variable: geometry <POINT [°]>

# use location biases to match Berlin, IL instead of Berlin, DE
geocode("Berlin", locbias = c(-100, 40), locbias_scale = 0.1, zoom = 7, osm_tag = "place")
#> Simple feature collection with 1 feature and 12 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: -89.90316 ymin: 39.75894 xmax: -89.90316 ymax: 39.75894
#> Geodetic CRS:  WGS 84
#> # A tibble: 1 × 13
#>     idx osm_type osm_id osm_key osm_value type  countrycode name   county  state
#>   <int> <chr>     <int> <chr>   <chr>     <chr> <chr>       <chr>  <chr>   <chr>
#> 1     1 R        126290 place   village   city  US          Berlin Sangam… Illi…
#> # ℹ 3 more variables: country <chr>, extent <list>, geometry <POINT [°]>

# latinization can help normalize search terms
geocode("Luatuanu\u2019u", latinize = FALSE) # fails
#> Simple feature collection with 1 feature and 11 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: -171.6764 ymin: -13.87342 xmax: -171.6764 ymax: -13.87342
#> Geodetic CRS:  WGS 84
#> # A tibble: 1 × 12
#>     idx osm_type  osm_id osm_key osm_value type  countrycode name  state country
#>   <int> <chr>      <int> <chr>   <chr>     <chr> <chr>       <chr> <chr> <chr>  
#> 1     1 W         1.10e9 place   village   city  WS          Luat… Ātua  Samoa  
#> # ℹ 2 more variables: extent <list>, geometry <POINT [°]>
geocode("Luatuanu\u2019u", latinize = TRUE)  # works
#> Simple feature collection with 1 feature and 11 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: -171.6764 ymin: -13.87342 xmax: -171.6764 ymax: -13.87342
#> Geodetic CRS:  WGS 84
#> # A tibble: 1 × 12
#>     idx osm_type  osm_id osm_key osm_value type  countrycode name  state country
#>   <int> <chr>      <int> <chr>   <chr>     <chr> <chr>       <chr> <chr> <chr>  
#> 1     1 W         1.10e9 place   village   city  WS          Luat… Ātua  Samoa  
#> # ℹ 2 more variables: extent <list>, geometry <POINT [°]>
```
