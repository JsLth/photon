skip_if_offline("photon.komoot.io")
skip_on_cran()

test_that("basic requests work", {
  res1 <- geocode("Berlin", progress = TRUE)
  expect_s3_class(res1, "sf")
  expect_equal(nrow(res1), 1)

  res2 <- geocode(c("Berlin", "Berlin"))
  expect_s3_class(res2, "sf")
  expect_equal(res2$idx, c(1, 2))

  res3 <- geocode("Berlin", bbox = c(xmin = 0, xmax = 13, ymin = 52, ymax = 53))
  expect_failure(expect_equal(res1, res3))

  res4a <- geocode("Berlin", locbias = c(-100, 40), locbias_scale = 0.1, zoom = 7, limit = 5)
  res4b <- geocode("Berlin", limit = 5)
  expect_failure(expect_equal(res4a, res4b))

  res5 <- geocode("notarealplace")
  expect_equal(nrow(res5), 1)
  expect_named(res5, c("idx", names(res_proto())))

  skip_on_os(c("mac", "linux", "solaris")) # iconv on unix is not easy
  res6 <- geocode("Luatuanu\u2019u")
  expect_false(anyNA(res6))
})

test_that("error messages are displayed", {
  expect_error(geocode("Berlin", lang = "test"), "supported")
})

test_that("basic reversing works", {
  df <- data.frame(lon = 8, lat = 52)
  res1 <- reverse(df, progress = TRUE)
  expect_s3_class(res1, "sf")
  expect_equal(nrow(res1), 1)

  df <- data.frame(lon = c(7, 8), lat = c(52, 52))
  res2 <- reverse(df)
  expect_s3_class(res2, "sf")
  expect_equal(res2$idx, c(1, 2))

  df <- data.frame(lon = 170, lat = 80)
  res3 <- reverse(df, radius = 1)
  expect_equal(nrow(res3), 1)
  expect_named(res3, c("idx", names(res_proto())))
})

test_that("reversing with sf works", {
  sf <- sf::st_sfc(sf::st_point(c(8, 52)), crs = 4326)
  sf2 <- sf::st_sfc(sf::st_point(c(8, 52)))
  res <- reverse(sf)
  expect_s3_class(res, "sf")
  expect_equal(nrow(res), 1)
  expect_error(reverse(sf2), class = "check_crs")
})

test_that("reversing with list works", {
  lst <- list(lon = 8, lat = 52)
  res <- reverse(lst)
  expect_s3_class(res, "sf")
  expect_equal(nrow(res), 1)
})

test_that("reversing only works with points", {
  sf <- sf::st_sfc(sf::st_point(c(8, 52)), sf::st_point(c(7, 52)))
  sf <- sf::st_cast(sf, "LINESTRING")
  expect_error(reverse(sf), class = "check_geometry")
})

test_that("structured works", {
  df <- data.frame(city = "Berlin", countrycode = "Berlin")
  res <- structured(df)
  expect_s3_class(res, "sf")
  expect_equal(nrow(res), 1)
})
