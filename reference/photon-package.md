# photon: High-Performance Geocoding using 'photon'

Features unstructured, structured and reverse geocoding using the
'photon' geocoding API <https://photon.komoot.io/>. Facilitates the
setup of local 'photon' instances to enable offline geocoding.

## Terms of use

From <https://photon.komoot.io> on using the public API:

*"You can use the API for your project, but please be fair - extensive
usage will be throttled. We do not guarantee for the availability and
usage might be subject of change in the future."*

Note that these terms only apply to the public API
([`new_photon()`](https://jslth.github.io/photon/reference/new_photon.md)),
and not to local instances (e.g.
[`new_photon(path = ".")`](https://jslth.github.io/photon/reference/new_photon.md))!
For the public API, the package sets a default of 1 request per second
(see below).

## Global options

A number of global options can be set that change the behavior of
package functions. These include:

- `photon_throttle`:

  Rate limit used to throttle requests. By default, no throttle is set
  for non-komoot instances. For komoot's public API, this option
  defaults to 1 request per second. See
  [`req_throttle`](https://httr2.r-lib.org/reference/req_throttle.html).

- `photon_max_tries`:

  Number of retries a failing request should do before ultimately
  aborting. Defaults to 3. See
  [`req_retry`](https://httr2.r-lib.org/reference/req_retry.html).

- `photon_debug`:

  Whether to echo the command of external processes and GET requests
  sent to photon. Defaults to `FALSE`.

- `photon_movers`:

  Whether moving verbosity is allowed. If `FALSE`, disables progress
  bars and spinners globally. Overwritten by local parameters. Defaults
  to `TRUE`. This option is useful for non-interactive sessions like
  RMarkdown.

- `photon_setup_warn`:

  Whether to convert warnings in the photon logs to R warnings. Many
  warnings in the log are somewhat useless, but some can be important.
  Defaults to `TRUE`.

## See also

Useful links:

- <https://github.com/jslth/photon/>

- <https://jslth.github.io/photon/>

- Report bugs at <https://github.com/jslth/photon/issues>

## Author

**Maintainer**: Jonas Lieth <jonas.lieth@gesis.org>
([ORCID](https://orcid.org/0000-0002-3451-3176)) \[copyright holder\]
