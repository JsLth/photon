# Changelog

## photon 0.7.4-1

- Adjusted tests and examples to be more resilient to server outages

## photon 0.7.4

CRAN release: 2025-10-29

- Increment photon version to 0.7.4
- Match package version to photon version
- Update examples to work in photon 0.7.4
- Set photon 0.7.4 as default and add a supersede warning if version \<
  0.7.0
- Add photon type (OpenSearch/ElasticSearch) to error message
- Adjust geocoding error detection to OpenSearch
- Update vignettes to OpenSearch
- Switch from Samoa to Monaco as example country (more reliable)
- Add `mount` argument to
  [`new_photon()`](https://jslth.github.io/photon/reference/new_photon.md).
  If `FALSE`, instance is created but not mounted.
- Add function
  [`with_photon()`](https://jslth.github.io/photon/reference/with_photon.md)
  to execute code using a local photon instance
- Add extra info to HTTP404 when search index download does not yield a
  result
- Add `$help()` method to show raw argument information from jar file
- Add CRS checks and transformations when an sf geometry is provided to
  [`reverse()`](https://jslth.github.io/photon/reference/reverse.md)
- Improve URL checker by relying on
  [`httr2::url_parse()`](https://httr2.r-lib.org/reference/url_parse.html)
- Fix `$download_data()` method not untaring archive and storing
  metadata
- Fix error detection during setup when encountering an exception
  without a timestamp
- Fix error detection not recognizing OpenSearch import errors
- Fix path arguments defaulting to `"."`
- Fix an example in
  [`new_photon()`](https://jslth.github.io/photon/reference/new_photon.md)
- Fix progress bar in
  [`reverse()`](https://jslth.github.io/photon/reference/reverse.md)
- Purge photon instances after examples

## photon 0.3.5

CRAN release: 2025-02-24

- Set `limit = 1` as default
  ([\#2](https://github.com/jslth/photon/issues/2))
- Increment photon version number
- Document `lang = "default"`
  ([\#8](https://github.com/jslth/photon/issues/8))
- Allow `osm_tags` and `layer` arguments to take vectors of length \> 1
  ([\#7](https://github.com/jslth/photon/issues/7))
- Fix typos and old info in documentation
  ([\#4](https://github.com/jslth/photon/issues/4))
- Add current date to metadata if search index is tagged as “latest”
  ([\#5](https://github.com/jslth/photon/issues/5))
- Fix typo in range assertion
  ([\#9](https://github.com/jslth/photon/issues/9))
- Add details to HTTP error messages
  ([\#6](https://github.com/jslth/photon/issues/6))
- Improve performance by querying duplicates only once
  ([\#10](https://github.com/jslth/photon/issues/10))
- Always keep number of rows from original dataset
  ([\#3](https://github.com/jslth/photon/issues/3))
- Fix broken `ps` command on newer Linux versions
- Made setups more stable by splitting logs
  ([\#11](https://github.com/jslth/photon/issues/11),
  [\#12](https://github.com/jslth/photon/issues/12))
- Handle `NA` as argument input more elegantly
- Added optional latinization
- Renamed `consent` argument of
  [`purge_java()`](https://jslth.github.io/photon/reference/purge_java.md)
  to `ask`

## photon 0.3.1

CRAN release: 2024-11-11

- Initial CRAN submission.
