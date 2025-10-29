## R CMD check results

0 errors | 0 warnings | 1 note


# photon 0.7.4

This is a re-submission


# photon 0.3.5

This is a re-submission


# photon 0.3.1

This is a re-submission, after review on 2024-11-05

### Comments by Benjamin Altmann

```
Please add a web reference for the API in the form <[https:.....]https:.....> to the
description of the DESCRIPTION file with no space after 'https:' and
angle brackets for auto-linking.
```

I added a reference of the public API to the DESCRIPTION file.

```
Some code lines in examples are wrapped in if(FALSE). Please never do
that. Ideally find toy examples that can be regularly executed and
checked. Lengthy examples (> 5 sec), can be wrapped in \donttest{}.
```

I replaced all `if (FALSE)`'s with sensible alternatives

  * All examples that require Java require a check of the newly exported `has_java("11")`
  * Examples of `purge_java()` are wrapped in `\dontrun` to prevent accidentally killing non-photon Java processes
  * The last example of `download_searchindex()` is wrapped in `\dontrun` because it can take hours and should never be run without full intent, even if `--run-donttest`
  * Examples of `structured()` are wrapped in `\dontrun` because they only work with a sophisticated photon setup

```
Please ensure that your functions do not write by default or in your
examples/vignettes/tests in the user's home filespace (including the
package directory and getwd()). This is not allowed by CRAN policies.
Please omit any default path in writing functions. In your
examples/vignettes/tests you can write to tempdir().
-> R/photon_local.R
```

I removed the default path from `photon$new()`.
