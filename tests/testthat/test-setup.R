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
  proc <- get_java_processes()
  message(capture.output(proc))
  expect_s3_class(proc, "data.frame")
  with_mocked_bindings(
    get_java_processes = function() data.frame(pids = 1),
    expect_error(purge_java(-1, consent = TRUE), class = "pid_not_java")
  )
  expect_vector(kill_process(rep(-1, 2)), integer(), size = 2)

  skip_if(nrow(get_java_processes()) > 0)
  expect_message(purge_java(consent = TRUE), regexp = "No java processes running.")
})

test_that("logs can be parsed", {
  logs <- readLines(test_path("fixtures/log_elasticsearch.txt"))
  logs <- rbind_list(lapply(logs, handle_log_conditions))
  expect_named(logs, c("ts", "thread", "type", "class", "msg"))
  expect_false(any(vapply(logs, FUN.VALUE = logical(1), \(x) all(is.na(x)))))

  logs <- readLines(test_path("fixtures/log_opensearch.txt"))
  logs <- rbind_list(lapply(logs, handle_log_conditions))
  expect_named(logs, c("ts", "thread", "type", "class", "msg"))
  expect_true(sum(vapply(logs, FUN.VALUE = logical(1), \(x) all(is.na(x)))) == 1)
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
  options(photon_setup_warn = FALSE)
  dir <- file.path(tempdir(), "photon")
  photon <- new_photon(path = dir, country = "samoa")
  on.exit({
    options(photon_setup_warn = NULL)
    photon$purge(ask = FALSE)
  })

  # test pre-setup
  expect_no_error(print(photon))
  photon <- new_photon(path = dir, country = "samoa")
  expect_no_message(new_photon(path = dir, quiet = TRUE))
  expect_error(photon$get_url(), class = "no_url_yet")
  expect_error(
    get_photon_executable(photon$path, get_latest_photon(), TRUE),
    regexp = "could not be found"
  )
  expect_false(photon$is_ready())
  expect_false(photon$is_running())

  # test setup
  photon$start(host = "127.0.0.1")
  expect_true(photon$is_running())
  expect_gt(nrow(geocode("Apai")), 0)
  photon$stop()
  expect_false(photon$is_running())

  # test error handling
  fail_dir <- file.path(tempdir(), "photon_fail")
  os_path <- file.path(fail_dir, "photon-opensearch-0.5.0.jar")
  dir.create(fail_dir, showWarnings = FALSE)
  expect_error(new_photon(fail_dir, opensearch = TRUE), class = "abort_opensearch_build")
  file.create(os_path)
  expect_message(
    new_photon(fail_dir, opensearch = TRUE, country = "Samoa"),
    regexp = "OpenSearch does not support ElasticSearch"
  )

  photon <- new_photon(path = fail_dir)
  expect_error(photon$import(), class = "import_error")
  logs <- photon$get_logs()
  expect_s3_class(logs, "data.frame")
  expect_contains(logs$type, "ERROR")
  expect_contains(names(logs), "rid")

  expect_error(photon$start(), class = "start_error")
  logs <- photon$get_logs()
  expect_equal(unique(logs$rid), c(1, 2))

  options(photon_setup_warn = TRUE)
  expect_warning(expect_error(photon$start(photon_opts = "-structured"), class = "start_error"))
  logs <- photon$get_logs()
  expect_contains(logs$type, c("WARN", "ERROR"))
  expect_match(logs$msg, "usage error", all = FALSE)
  expect_equal(unique(logs$rid), c(1, 2, 3))

  expect_warning(
    expect_error(photon$import(structured = TRUE)),
    class = "structured_elasticsearch_error"
  )
})

