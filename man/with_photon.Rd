% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/new_photon.R
\name{with_photon}
\alias{with_photon}
\title{Local photon instances}
\usage{
with_photon(photon, code)
}
\arguments{
\item{photon}{An object of class \code{\link[=new_photon]{photon}} that is
temporarily mounted to the session.}

\item{code}{Code to execute in the temporary environment.}
}
\value{
The results of the evaluation of the \code{code} argument.
}
\description{
Evaluate R code with a photon instance without changing the active photon
mount.
}
\examples{
# Get a public instance
pub_photon <- new_photon()

# Mount a custom instance
new_photon(url = "https://localhost:8001/")

# Geocode with the public instance only once
with_photon(pub_photon, geocode("Rutland"))

# The custom instance is still mounted
get_instance()
}
