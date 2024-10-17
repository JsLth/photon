skip_if_offline("photon.komoot.io")
skip_on_cran()

new_photon()

test_that("basic requests work", {
  res <- geocode("Berlin")
  expect_s3_class(res, "sf")
  expect_equal(nrow(res), 3)

  res <- geocode(c("Berlin", "Berlin"))
  expect_s3_class(res, "sf")
  expect_equal(res$idx, rep(c(1, 2), each = 3))
})


test_that("basic reversing works", {
  df <- data.frame(lon = 8, lat = 52)
  res <- reverse(df)
  expect_s3_class(res, "sf")
  expect_equal(nrow(res), 3)

  df <- data.frame(lon = c(7, 8), lat = c(52, 52))
  res <- reverse(df)
  expect_s3_class(res, "sf")
  expect_equal(res$idx, rep(c(1, 2), each = 3))
})

test_that("reversing with sf works", {
  sf <- sf::st_sfc(sf::st_point(c(8, 52)))
  res <- reverse(sf)
  expect_s3_class(res, "sf")
  expect_equal(nrow(res), 3)
})


test_that("reversing only works with points", {
  sf <- sf::st_sfc(sf::st_point(c(8, 52)), sf::st_point(c(7, 52)))
  sf <- sf::st_cast(sf, "LINESTRING")
  expect_error(reverse(sf), class = "check_geometry")
})
