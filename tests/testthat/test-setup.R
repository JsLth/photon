test_that("remote photons work", {
  clear_cache()
  expect_error(get_instance(), class = "instance_missing")
  photon <- new_photon()
  expect_true(is_komoot(photon$get_url()))
  expect_error(structured(), regexp = "disabled")
  photon <- new_photon(url = "https://test.org")
  expect_equal(photon$get_url(), "https://test.org")
})

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
  skip_on_cran()
  proc <- get_java_processes()
  message(capture.output(proc))
  expect_s3_class(proc, "data.frame")
  with_mocked_bindings(
    get_java_processes = function() data.frame(pids = 1),
    expect_error(purge_java(-1L, ask = FALSE), class = "pid_not_java")
  )
  expect_vector(kill_process(rep(-1, 2)), integer(), size = 2)

  skip_if(nrow(get_java_processes()) > 0)
  expect_message(purge_java(ask = FALSE), regexp = "No java processes running.")
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

test_that("search indices are matched", {
  skip_if_offline("graphhopper.com")
  de_latest <- download_database(only_url = TRUE, region = "Germany")
  expect_equal(basename(de_latest), "photon-db-germany-1.0-latest.tar.bz2")
  na_latest <- download_database(only_url = TRUE, region = "North America")
  expect_equal(basename(na_latest), "photon-db-north-america-1.0-latest.tar.bz2")
  global_latest <- download_database(only_url = TRUE, region = "planet")
  expect_equal(basename(global_latest), "photon-db-planet-1.0-latest.tar.bz2")
  expect_error(
    download_database(only_url = TRUE, region = "not a country"),
    class = "country_invalid"
  )
})

test_that("opensearch is denied when unsupported", {
  expect_error(
    download_photon(tempdir(), version = "0.5.0", opensearch = TRUE),
    class = "opensearch_unsupported"
  )
})

skip_on_cran()
skip_if_offline("github.com")
skip_if_offline("graphhopper.com")
skip_if_not(has_java("11"))

describe("photon_local", {
  options(photon_setup_warn = FALSE)
  on.exit(options(photon_setup_warn = NULL), add = TRUE)
  dir <- file.path(tempdir(), "photon")
  photon <- new_photon(path = dir, region = "andorra")
  on.exit(photon$purge(ask = FALSE), add = TRUE)

  it("can print", {
    expect_no_error(print(photon))
  })

  photon <- new_photon(path = dir, region = "andorra")

  it("can suppress verbosity", {
    expect_no_message(new_photon(path = dir, quiet = TRUE))
  })

  it("communicates if not yet set up", {
    expect_error(photon$get_url(), class = "no_url_yet")
    expect_error(
      get_photon_executable(photon$path, "0.1.0", FALSE),
      regexp = "could not be found"
    )
    expect_false(photon$is_ready())
    expect_false(photon$is_running())
  })

  it("can start", {
    photon$start(host = "127.0.0.1")
    expect_true(photon$is_running())
    expect_false(anyNA(geocode("Monte Carlo")$osm_id))
    expect_error(photon$start(host = "127.0.0.1"), class = "photon_already_running")
  })

  it("warns if data cannot be removed", {
    with_mocked_bindings(
      unlink = \(...) 1L,
      .package = "base",
      expect_warning(photon$remove_data(), class = "photon_data_not_removed")
    )
  })

  it("can stop", {
    photon$stop()
    expect_false(photon$is_running())
  })

  fail_dir <- file.path(tempdir(), "photon_fail")
  photon <- new_photon(path = fail_dir)

  it("intercepts start errors correctly", {
    expect_error(photon$start(), class = "start_error")
    logs <- photon$get_logs()
    expect_s3_class(logs, "data.frame")
    expect_contains(logs$type, "ERROR")
    expect_contains(names(logs), "rid")
  })

  it("intercepts import errors correctly", {
    expect_error(photon$import(), class = "import_error")
    logs <- photon$get_logs()
    expect_equal(unique(logs$rid), c(1, 2))
  })

  it("intercepts usage errors correctly", {
    options(photon_setup_warn = TRUE)
    on.exit(options(photon_setup_warn = NULL), add = TRUE)
    expect_warning(expect_error(photon$start(photon_opts = "-notanoption"), class = "start_error"))
    logs <- photon$get_logs()
    expect_contains(logs$type, c("WARN", "ERROR"))
    expect_match(logs$msg, "usage error", all = FALSE)
    expect_equal(unique(logs$rid), c(1, 2, 3))
  })

  it("can remove index data", {
    photon$stop()
    expect_no_warning(photon$remove_data())
    expect_false(dir.exists(file.path(photon$path, "photon_data")))
  })

  it("can run help", {
    expect_output(photon$help(), regexp = "Usage: <main class>")
  })

  it("can download data manually", {
    photon$remove_data()
    photon$download_data("andorra")
    photon$start(host = "127.0.0.1")
    photon$stop()
  })
})


test_that("with_photon works", {
  photon1 <- new_photon(url = "https://test.org")
  photon2 <- new_photon()
  expect_error(with_photon(photon1, geocode("Berlin")), regexp = "Could not resolve")
})
