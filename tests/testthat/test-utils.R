test_that("character tools work", {
  expect_equal(capitalize_char("test"), "Test")
  expect_equal(regex_match(c("test1", "test2"), "[0-9]"), list("1", "2"))
})

test_that("%||% works", {
  expect_equal(1 %||% 2, 1)
  expect_equal(NULL %||% 2, 2)
})

test_that("url tools work", {
  expect_true(is_url(url1))
  expect_true(is_url(url2))
  expect_true(is_url(url3))
  expect_true(is_url(url4))
  expect_false(is_url(url5))
  expect_true(is_url(url6))

  expect_true(is_komoot("https://photon.komoot.io/"))
})

test_that("rbind_list works", {
  withr::local_package("sf")
  df1 <- data.frame(a = 1, b = "a")
  df2 <- data.frame(a = 2, c = "b")
  df3 <- data.frame()
  sf1 <- st_sf(
    a = c(1, 2),
    geometry = st_sfc(st_point(c(1, 2)), st_point(c(5, 8)))
  )
  sf2 <- st_sf(
    b = c(3, 4),
    geometry = st_sfc(st_point(c(4, 5)), st_point(c(3, 5)))
  )

  no_sf <- rbind_list(list(df1, df2))
  no_crs <- rbind_list(list(sf1, sf2))

  expect_length(no_sf$a, 2)
  expect_equal(no_sf$b, c("a", NA))
  expect_s3_class(no_crs, "sf")
  expect_identical(st_crs(no_crs), NA_crs_)

  st_crs(sf1) <- 4326
  expect_error(rbind_list(list(sf1, sf2)))

  st_crs(sf2) <- 4326
  expect_no_error(rbind_list(list(sf1, sf2)))

  expect_identical(rbind_list(list(df2, df3)), df2)
})
