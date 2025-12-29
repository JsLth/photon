# Is Java installed?

Utility function to check if Java is installed and if it has the right
version.

## Usage

``` r
has_java(version = NULL)
```

## Arguments

- version:

  Character string specifying the minimum version of Java. If the
  installed Java version is lower than this, returns `FALSE`. If `NULL`,
  only checks if any kind of Java is installed on the system.

## Value

A logical vector of length 1.

## Examples

``` r
has_java() # Is Java installed?
#> [1] TRUE
has_java("11") # Is Java > 11 installed?
#> [1] TRUE
```
