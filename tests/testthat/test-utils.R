test_that("character tools work", {
  expect_equal(regex_match(c("test1", "test2"), "[0-9]"), list("1", "2"))
  expect_equal(regex_match("abc", "a(b)c", i = 2), "b")
})

test_that("%||% works", {
  expect_equal(1 %||% 2, 1)
  expect_equal(NULL %||% 2, 2)
})

test_that("url tools work", {
  url1 <- "localhost:8080"
  url2 <- "127.0.0.1:8080"
  url3 <- "https://localhost:8080/path/to/sth"
  url4 <- "google.com"
  url5 <- "localhost"

  expect_true(is_url(url1))
  expect_true(is_url(url2))
  expect_true(is_url(url3))
  expect_true(is_url(url4))
  expect_false(is_url(url5))

  expect_true(is_komoot("https://photon.komoot.io/"))
})

test_that("rbind_list works", {
  df1 <- data.frame(a = 1, b = "a")
  df2 <- data.frame(a = 2, c = "b")
  df3 <- data.frame()
  sf1 <- sf::st_sf(
    a = c(1, 2),
    geometry = sf::st_sfc(sf::st_point(c(1, 2)), sf::st_point(c(5, 8)))
  )
  sf2 <- sf::st_sf(
    b = c(3, 4),
    geometry = sf::st_sfc(sf::st_point(c(4, 5)), sf::st_point(c(3, 5)))
  )

  no_sf <- rbind_list(list(df1, df2))
  no_crs <- rbind_list(list(sf1, sf2))

  expect_length(no_sf$a, 2)
  expect_equal(no_sf$b, c("a", NA))
  expect_s3_class(no_crs, "sf")
  expect_identical(sf::st_crs(no_crs), sf::NA_crs_)

  sf::st_crs(sf1) <- 4326
  expect_error(rbind_list(list(sf1, sf2)))

  sf::st_crs(sf2) <- 4326
  expect_no_error(rbind_list(list(sf1, sf2)))

  expect_identical(rbind_list(list(df2, df3)), df2)
  expect_no_warning(rbind_list(list(sf::st_sf(geometry = sf::st_sfc()))))
})

test_that("tibble dependency is soft", {
  with_mocked_bindings(
    loadable = function(x) FALSE,
    expect_failure(expect_in("tbl", class(as_data_frame(data.frame()))))
  )
})

test_that("assertions work", {
  assert_length(1, 1)
  assert_length(c(1, 2), 2)
  assert_length(NULL, null = TRUE)
  assert_vector(1, "double")
  assert_vector("a", "character")
  assert_true_or_false(TRUE)
  assert_true_or_false(FALSE)
  assert_dir(tempdir())
  assert_url("google.com")
  assert_url("localhost:8082")
  assert_class(data.frame(), "data.frame")
  assert_named(list(a = 1), c("a", "b"))
  assert_range(5, min = 1, max = 6)

  expect_error(assert_length(1, 2), class = "assert_length")
  expect_error(assert_vector(1, "logical"), class = "assert_vector")
  expect_error(assert_vector(list(), "logical"), class = "assert_vector")
  expect_error(assert_true_or_false(NA), class = "assert_true_or_false")
  expect_error(assert_dir("not a dir"), class = "assert_dir")
  expect_error(assert_url("not a url"), class = "assert_url")
  expect_error(assert_class("not a df", "data.frame"), class = "assert_class")
  expect_error(assert_named(list(a = 1), "b"), class = "assert_named")
  expect_error(assert_named(list(a = 1, b = 2), "b", all = TRUE), class = "assert_named")
  expect_error(assert_range(5, min = 6, max = 10), class = "assert_range")
  expect_error(assert_range(5, min = 1, max = 2), class = "assert_range")
})
