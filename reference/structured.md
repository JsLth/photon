# Structured geocoding

Geocode a set of place information such as street, house number, or post
code. Structured geocoding is generally more accurate but requires more
information than [unstructured
geocoding](https://jslth.github.io/photon/reference/geocode.md).

Note that structured geocoding must be specifically enabled when
building a Nominatim database. It is generally not available on komoot's
public API and on pre-built search indices through
[`download_searchindex`](https://jslth.github.io/photon/reference/download_searchindex.md).
See
[`vignette("nominatim-import", package = "photon")`](https://jslth.github.io/photon/articles/nominatim-import.md)
for details. You can use the helper function `has_structured_support()`
to check if the current API supports structured geocoding.

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
if (FALSE) { # \dontrun{
# structured() requires an OpenSearch instance with structured support
# the following code will not work off the shelf
# refer to vignette("nominatim-import") for details
dir <- file.path(tempdir(), "photon")
photon <- new_photon(dir, opensearch = TRUE)
photon$import(password = "psql_password", structured = TRUE)
photon$start()

# check if structured() is supported
has_structured_support()

# structured() works on dataframes containing structurized data
place_data <- data.frame(
  housenumber = c(NA, "77C", NA),
  street = c("Falealilli Cross Island Road", "Main Beach Road", "Le Mafa Pass Road"),
  state = c("Tuamasaga", "Tuamasaga", "Atua")
)
structured(place_data, limit = 1)

# countries must be specified as iso2 country codes
structured(data.frame(countrycode = "ws"))

# traditional parameters from geocode() can also be used but are much more niche
structured(data.frame(city = "Apia"), layer = "house") # matches nothing

# structured geocoding can discern small differences in places
safune <- data.frame(
  city = c("Safune", "Safune"),
  state = c("Gaga'ifomauga", "Tuamasaga")
)
structured(safune, limit = 1)
} # }
```
