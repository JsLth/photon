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

  res4 <- geocode("Berlin", locbias = c(10, 52), zoom = 12, locbias_scale = 0.1)
  expect_failure(expect_equal(res1, res4))

  res5 <- geocode(c("notarealplace"))
  expect_equal(nrow(res5), 1)
  expect_named(res5, c("idx", names(res_proto())))
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
  sf <- sf::st_sfc(sf::st_point(c(8, 52)))
  res <- reverse(sf)
  expect_s3_class(res, "sf")
  expect_equal(nrow(res), 1)
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

test_that("structured accepts parameters", {
  skip_webfakes <- function(web) {
    failed <- inherits(web, "try-error")
    skip_if(failed, "webfakes bug: https://github.com/r-lib/webfakes/issues/103")
  }
  skip_if_not_installed("webfakes")

  app <- webfakes::new_app()
  app$get("/structured", function(req, res) {
    if (length(req$query)) {
      out <- readChar(testthat::test_path("fixtures/api_response.json"), nchar = 388)
      res$send(out)
    } else {
      res$send_status(400)
    }
  })
  web <- try(webfakes::local_app_process(app))
  skip_webfakes(web)
  new_photon(url = web$url())
  expect_equal(nrow(structured(data.frame(street = "test"), progress = TRUE)), 1)
  expect_error(structured(list(a = "test")), class = "assert_named")
})
