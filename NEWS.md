# photon 0.7.2

* Increment photon version to 0.7.2
* Match package version to photon version
* Update examples to work in photon 0.7.2
* Set photon 0.7.2 as default and add a supersede warning if version < 0.7.0
* Add photon type (OpenSearch/ElasticSearch) to error message
* Adjust geocoding error detection to OpenSearch
* Update vignettes to OpenSearch
* Switch from Samoa to Monaco as example country (more reliable)
* Add `mount` argument to `new_photon()`. If `FALSE`, instance is created but not mounted.
* Add function `with_photon()` to execute code using a local photon instance
* Add extra info to HTTP404 when search index download does not yield a result
* Fix `$download_data()` method not untaring archive and storing metadata
* Add `$help()` method to show raw argument information from jar file
* Improve URL checker by relying on `httr2::url_parse()`
* Fix error detection during setup when encountering an exception without a timestamp
* Fix path arguments defaulting to `"."`
* Fix an example in `new_photon()`
* Purge photon instances after examples


# photon 0.3.5

* Set `limit = 1` as default (#2)
* Increment photon version number
* Document `lang = "default"` (#8)
* Allow `osm_tags` and `layer` arguments to take vectors of length > 1 (#7)
* Fix typos and old info in documentation (#4)
* Add current date to metadata if search index is tagged as "latest" (#5)
* Fix typo in range assertion (#9)
* Add details to HTTP error messages (#6)
* Improve performance by querying duplicates only once (#10)
* Always keep number of rows from original dataset (#3)
* Fix broken `ps` command on newer Linux versions
* Made setups more stable by splitting logs (#11, #12)
* Handle `NA` as argument input more elegantly
* Added optional latinization
* Renamed `consent` argument of `purge_java()` to `ask`

# photon 0.3.1

* Initial CRAN submission.
