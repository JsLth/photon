# Latinization

Helper tool to transliterate various encodings to latin. Attempts to
convert a character vector from its current encoding to `"latin1"` and -
if it fails - defaults back to the original term. This can be useful for
[`geocode`](https://jslth.github.io/photon/reference/geocode.md) and
[`structured`](https://jslth.github.io/photon/reference/structured.md)
when attempting to geocode terms containing symbols that photon does not
support.

## Usage

``` r
latinize(x, encoding = "latin1")
```

## Arguments

- x:

  A character vector.

- encoding:

  Encoding that the strings in `x` should be converted to. If the
  conversion fails, defaults back to the original encoding. Defaults to
  `"latin1"`.

## Value

The transliterated vector of the same length as `x`. `NA`s are avoided.

## Examples

``` r
# converts fancy apostrophes to normal ones
latinize("Luatuanu\u2019u")
#> [1] "Luatuanu’u"

# does nothing
latinize("Berlin")
#> [1] "Berlin"

# also does nothing, although it would fail with `iconv`
latinize("\u0391\u03b8\u03ae\u03bd\u03b1")
#> [1] "Αθήνα"
```
