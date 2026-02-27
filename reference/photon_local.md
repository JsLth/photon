# Local photon instance

This R6 class is used to initialize and manage local photon instances.
It can download and setup the Java, the photon executable, and the
necessary OpenSearch index. It can start, stop, and query the status of
the photon instance. It is also the basis for geocoding requests as it
is used to retrieve the URL for geocoding.

## Value

A list containing four elements:

- **status**: Shows `"Ok"` when photon is running without problems.
  **import_date**: Time stamp when the database was built. **version**:
  Photon version currently running. **git_commit**: Git commit string of
  the photon version currently running.

## Search indices

Search indices can be self-provided by importing an existing Nominatim
database or they can be downloaded from the [Photon download
server](https://nominatim.org/2020/10/21/photon-country-extracts.html).
If you want to download pre-built search indices, simply provide a
`region` string during initialization or use the `$download_data`
method. Pre-built search indices do not come with support for structured
geocoding.

If you want to build from Nominatim, do not provide a region string and
use the `$import()` method. See
[`vignette("nominatim-import", package = "photon")`](https://jslth.github.io/photon/articles/nominatim-import.md)
for details on how to import from Nominatim.

To enable structured geocoding, the photon geocoder needs to be built to
support OpenSearch. Since photon 0.7.0, OpenSearch jar files are the
standard and ElasticSearch is deprecated.

## Super class

[`photon::photon`](https://jslth.github.io/photon/reference/photon-package.md)
-\> `photon_local`

## Public fields

- `path`:

  Path to the directory where the photon instance is stored.

- `proc`:

  [`process`](http://processx.r-lib.org/reference/process.md) object
  that handles the external process running photon.

## Methods

### Public methods

- [`photon_local$new()`](#method-photon_local-new)

- [`photon_local$mount()`](#method-photon_local-mount)

- [`photon_local$info()`](#method-photon_local-info)

- [`photon_local$help()`](#method-photon_local-help)

- [`photon_local$purge()`](#method-photon_local-purge)

- [`photon_local$import()`](#method-photon_local-import)

- [`photon_local$start()`](#method-photon_local-start)

- [`photon_local$stop()`](#method-photon_local-stop)

- [`photon_local$status()`](#method-photon_local-status)

- [`photon_local$download_data()`](#method-photon_local-download_data)

- [`photon_local$remove_data()`](#method-photon_local-remove_data)

- [`photon_local$is_running()`](#method-photon_local-is_running)

- [`photon_local$is_ready()`](#method-photon_local-is_ready)

- [`photon_local$get_url()`](#method-photon_local-get_url)

- [`photon_local$get_logs()`](#method-photon_local-get_logs)

- [`photon_local$clone()`](#method-photon_local-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize a local photon instance. If necessary, downloads the photon
executable, the search index, and Java.

#### Usage

    photon_local$new(
      path,
      photon_version = NULL,
      region = NULL,
      opensearch = TRUE,
      mount = TRUE,
      overwrite = FALSE,
      quiet = FALSE
    )

#### Arguments

- `path`:

  Path to a directory where the photon executable and data should be
  stored.

- `photon_version`:

  Version of photon to be used. A list of all releases can be found
  here: <https://github.com/komoot/photon/releases/>. Ignored if `jar`
  is given. If `NULL`, uses the latest known version (Currently: 1.0.0).

- `region`:

  Character string that identifies a region or country. An extract for
  this region will be downloaded. If `"planet"`, downloads a global
  extract (see note). Run
  [`list_regions()`](https://jslth.github.io/photon/reference/download_database.md)
  to get an overview of available regions. You can specify countries
  using any code that can be translated by
  [`countrycode`](https://vincentarelbundock.github.io/countrycode/man/countrycode.html).

- `opensearch`:

  Deprecated for photon versions \>= 1.0.0 and superseded for photon
  versions \>= 0.7.0. If `TRUE`, attempts to download the OpenSearch
  version of photon. OpenSearch-based photon supports structured
  geocoding. If `FALSE`, falls back to ElasticSearch. Since photon
  0.7.0, OpenSearch is the default and since 1.0.0, ElasticSearch is not
  supported anymore.

- `mount`:

  If `TRUE`, mounts the object to the session so that functions like
  [`geocode`](https://jslth.github.io/photon/reference/geocode.md)
  automatically detect the new instance. If `FALSE`, initializies the
  instance but doesn't mount it to the session. Defaults to `TRUE`.

- `overwrite`:

  If `TRUE`, overwrites existing jar files and search indices when
  initializing a new instance. Defaults to `FALSE`.

- `quiet`:

  If `TRUE`, suppresses all informative messages.

------------------------------------------------------------------------

### Method `mount()`

Attach the object to the session. If mounted, all geocoding functions
send their requests to the URL of this instance. Manually mounting is
useful if you want to switch between multiple photon instances.

#### Usage

    photon_local$mount()

------------------------------------------------------------------------

### Method `info()`

Retrieve metadata about the java and photon version used as well as the
region and creation date of the search index.

#### Usage

    photon_local$info()

#### Returns

A list containing the java version, the photon version, and if
applicable, the spatial and temporal coverage of the search index.

------------------------------------------------------------------------

### Method [`help()`](https://rdrr.io/r/utils/help.html)

Print the default arguments to the R console. This can be helpful to get
a list of additional photon arguments for `$start()` or `$import()`.

#### Usage

    photon_local$help()

#### Returns

Nothing, but prints to the console.

------------------------------------------------------------------------

### Method `purge()`

Kill the photon process and remove the directory. Useful to get rid of
an instance entirely.

#### Usage

    photon_local$purge(ask = TRUE)

#### Arguments

- `ask`:

  If `TRUE`, asks for confirmation before purging the instance.

#### Returns

`NULL`, invisibly.

------------------------------------------------------------------------

### Method `import()`

Import a Postgres Nominatim database to photon. Runs the photon jar file
using the additional parameter `-nominatim-import`. Requires a running
Nominatim database that can be connected to.

#### Usage

    photon_local$import(
      host = "127.0.0.1",
      port = 5432,
      database = "nominatim",
      user = "nominatim",
      password = "",
      structured = FALSE,
      update = FALSE,
      enable_update_api = FALSE,
      languages = c("en", "fr", "de", "it"),
      countries = NULL,
      extra_tags = NULL,
      json = FALSE,
      timeout = 60,
      java_opts = NULL,
      photon_opts = NULL
    )

#### Arguments

- `host`:

  Postgres host of the database. Defaults to `"127.0.0.1"`.

- `port`:

  Postgres port of the database. Defaults to `5432`.

- `database`:

  Postgres database name. Defaults to `"nominatim"`.

- `user`:

  Postgres database user. Defaults to `"nominatim"`.

- `password`:

  Postgres database password. Defaults to `""`.

- `structured`:

  If `TRUE`, enables structured query support when importing the
  database. This allows the usage of
  [`structured`](https://jslth.github.io/photon/reference/structured.md).
  Structured queries are only supported in the OpenSearch version of
  photon. See section "OpenSearch" above. Defaults to `FALSE`.

- `update`:

  If `TRUE`, fetches updates from the Nominatim database, updating the
  search index without offering an API. If `FALSE`, imports the database
  an deletes the previous index. Defaults to `FALSE`.

- `enable_update_api`:

  If `TRUE`, enables an additional endpoint `/nominatim-update`, which
  allows updates from Nominatim databases.

- `languages`:

  Character vector specifying the languages to import from the Nominatim
  databases. Defaults to English, French, German, and Italian.

- `countries`:

  Character vector specifying the country codes to import from the
  Nominatim database. Defaults to all country codes.

- `extra_tags`:

  Character vector specifying extra OSM tags to import from the
  Nominatim database. These tags are used to augment geocoding results.
  Defaults to `NULL`.

- `json`:

  If `TRUE`, dumps the imported Nominatim database to a JSON file and
  returns the path to the output file. Defaults to `FALSE`.

- `timeout`:

  Time in seconds before the java process aborts. Defaults to 60
  seconds.

- `java_opts`:

  Character vector of further flags passed on to the `java` command.

- `photon_opts`:

  Character vector of further flags passed on to the photon jar in the
  java command. See
  [`cmd_options`](https://jslth.github.io/photon/reference/cmd_options.md)
  for a helper function.

------------------------------------------------------------------------

### Method [`start()`](https://rdrr.io/r/stats/start.html)

Start a local instance of the Photon geocoder. Runs the jar executable
located in the instance directory.

#### Usage

    photon_local$start(
      host = "0.0.0.0",
      port = "2322",
      ssl = FALSE,
      timeout = 60,
      countries = NULL,
      threads = 1,
      query_timeout = NULL,
      max_results = NULL,
      max_reverse_results = NULL,
      java_opts = NULL,
      photon_opts = NULL
    )

#### Arguments

- `host`:

  Character string of the host name that the geocoder should be opened
  on.

- `port`:

  Port that the geocoder should listen to.

- `ssl`:

  If `TRUE`, uses `https`, otherwise `http`. Defaults to `FALSE`.

- `timeout`:

  Time in seconds before the java process aborts. Defaults to 60
  seconds.

- `countries`:

  Character vector of countries to import. By default, all countries in
  the database are imported.

- `threads`:

  Number of threads in parallel. Defaults to 1.

- `query_timeout`:

  Time in seconds after which to cancel queries to Photon. Defaults to 7
  seconds.

- `max_results`:

  Maximum number of results returned to
  [`geocode`](https://jslth.github.io/photon/reference/geocode.md) and
  [`structured`](https://jslth.github.io/photon/reference/structured.md).
  Defaults to 50.

- `max_reverse_results`:

  Maximum number of results returned to
  [`reverse`](https://jslth.github.io/photon/reference/reverse.md).
  Defaults to 50.

- `java_opts`:

  Character vector of further flags passed on to the `java` command.

- `photon_opts`:

  Character vector of further flags passed on to the photon jar in the
  java command. See
  [`cmd_options`](https://jslth.github.io/photon/reference/cmd_options.md)
  for a helper function.

#### Details

While there is a certain way to determine if a photon instance is ready,
there is no clear way as of yet to determine if a photon setup has
failed. Due to this, a failing setup may sometimes hang instead of
emitting an error. In this case, please open a bug report.

------------------------------------------------------------------------

### Method [`stop()`](https://rdrr.io/r/base/stop.html)

Kills the running photon process.

#### Usage

    photon_local$stop()

------------------------------------------------------------------------

### Method `status()`

Returns information from a live server about the photon version used and
the date of data import.

#### Usage

    photon_local$status()

------------------------------------------------------------------------

### Method `download_data()`

Downloads a search index using
[`download_database`](https://jslth.github.io/photon/reference/download_database.md).

#### Usage

    photon_local$download_data(region, json = FALSE)

#### Arguments

- `region`:

  Character string that identifies a region or country. An extract for
  this region will be downloaded. If `"planet"`, downloads a global
  extract (see note). Run
  [`list_regions()`](https://jslth.github.io/photon/reference/download_database.md)
  to get an overview of available regions. You can specify countries
  using any code that can be translated by
  [`countrycode`](https://vincentarelbundock.github.io/countrycode/man/countrycode.html).

- `json`:

  Extracts come in two forms: JSON dumps and pre-build databases.
  Pre-built databases are more convenient but less flexible and are not
  available for all regions. If you wish or need to build your own
  database, set `json = TRUE` and use the `$import()` method.

------------------------------------------------------------------------

### Method `remove_data()`

Removes the data currently used in the photon directory. This only
affects the unpacked `photon_data` directory, not archived files.

#### Usage

    photon_local$remove_data()

------------------------------------------------------------------------

### Method `is_running()`

Checks whether the photon instance is running and ready. The difference
to `$is_ready()` is that `$is_running()` checks specifically if the
running photon instance is managed by a process from its own `photon`
object. In other words, `$is_running()` returns `TRUE` if both
`$proc$is_alive()` and `$is_ready()` return `TRUE`. This method is
useful if you want to ensure that the `photon` object can control its
photon server (mostly internal use).

#### Usage

    photon_local$is_running()

#### Returns

A logical of length 1.

------------------------------------------------------------------------

### Method `is_ready()`

Checks whether the photon instance is ready to take requests. This is
the case if the photon server returns a HTTP 400 when sending a
queryless request. This method is useful if you want to check whether
you can send requests.

#### Usage

    photon_local$is_ready()

#### Returns

A logical of length 1.

------------------------------------------------------------------------

### Method `get_url()`

Constructs the URL that geocoding requests should be sent to.

#### Usage

    photon_local$get_url()

#### Returns

A URL to send requests to.

------------------------------------------------------------------------

### Method `get_logs()`

Retrieve the logs of previous photon runs.

#### Usage

    photon_local$get_logs()

#### Returns

Returns a dataframe containing the run ID (`rid`, the highest number is
the most recent run), a timestamp (`ts`), the thread, the log type
(INFO, WARN, or ERROR), the class trace and the error message.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    photon_local$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # getFromNamespace("is_online", "photon")("graphhopper.com") && getFromNamespace("photon_run_examples", "photon")()
if (has_java("11")) {
dir <- file.path(tempdir(), "photon")

# start a new instance using a Monaco extract
photon <- new_photon(path = dir, region = "Andorra")

# start a new instance with an older photon version
photon <- new_photon(path = dir, photon_version = "0.4.1", opensearch = FALSE)
}

if (FALSE) { # \dontrun{
# import a nominatim database using OpenSearch photon
# this example requires the OpenSearch version of photon and a running
# Nominatim server.
photon <- new_photon(path = dir, opensearch = TRUE)
photon$import(photon_options = cmd_options(port = 29146, password = "pgpass"))} # }

photon$purge(ask = FALSE)
}
```
