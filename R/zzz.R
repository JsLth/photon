.onLoad <- function(libname, pkgname) {
  # register public api on load
  # this ensures that geocoding works directly when loading the package
  new_photon() # nocov
}
