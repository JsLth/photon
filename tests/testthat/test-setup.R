clear_cache()

test_that("java checks work", {
  with_mocked_bindings(
    has_java = function() FALSE,
    expect_error(get_java_version(), class = "java_missing_error")
  )
  with_mocked_bindings(
    get_java_version = function(...) "8",
    expect_error(check_jdk_version("11"), class = "java_version_error")
  )
})

test_that("java can be purged", {
  expect_error(purge_java(-1, consent = TRUE), class = "pid_not_java")
  expect_vector(kill_process(rep(-1, 2)), integer(), size = 2)

  skip_if(nrow(get_java_processes()) > 0)
  expect_message(purge_java(consent = TRUE), regexp = "No java processes running.")
})

test_that("remote photons work", {
  expect_error(get_instance(), class = "instance_missing")
  photon <- new_photon()
  expect_true(is_komoot(photon$get_url()))
  expect_error(structured(), regexp = "disabled")
  photon <- new_photon(url = "test.org")
  expect_equal(photon$get_url(), "test.org")
})

skip_if_offline("graphhopper.com")
skip_on_cran()

test_that("search indices are matched", {
  de_latest <- download_searchindex(only_url = TRUE, country = "Germany")
  expect_equal(basename(de_latest), "photon-db-de-latest.tar.bz2")
  global_latest <- download_searchindex(only_url = TRUE, country = "planet")
  expect_equal(basename(global_latest), "photon-db-latest.tar.bz2")
  global_time <- download_searchindex(only_url = TRUE, date = Sys.Date())
  expect_match(basename(global_time), "photon-db-mc-[0-9]+\\.tar\\.bz2")
  expect_error(
    download_searchindex(only_url = TRUE, date = Sys.Date(), exact = TRUE),
    class = "no_index_match"
  )
  expect_error(
    download_searchindex(only_url = TRUE, country = "not a country"),
    class = "country_invalid"
  )
})

skip_if_offline("github.com")
skip_if_offline("corretto.aws")
skip_if_not(has_java())

test_that("local setup works", {
  dir <- file.path(tempdir(), "photon")
  photon <- new_photon(path = dir, country = "samoa")
  on.exit(photon$purge(ask = FALSE))
  expect_no_error(print(photon))
  photon <- new_photon(path = dir, country = "samoa")
  expect_no_message(new_photon(path = dir, quiet = TRUE))
  expect_error(photon$get_url(), class = "no_url_yet")

  photon$start(host = "127.0.0.1")
  expect_true(photon$is_running())
  expect_gt(nrow(geocode("Apai")), 0)
  photon$stop()
  expect_false(photon$is_running())
})

