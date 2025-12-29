# Purge Java processes

Kill all or selected running Java processes. This function is useful to
stop Photon instances when not being able to kill the
[`process`](http://processx.r-lib.org/reference/process.md) objects. Be
aware that you can also kill Java processes other than the photon
application using this function!

## Usage

``` r
purge_java(pids = NULL, ask = TRUE)
```

## Arguments

- pids:

  PIDs to kill. The PIDs should be Java processes. If `NULL`, tries to
  kill all Java processes.

- ask:

  If `TRUE`, asks for consent before killing the processes. Defaults to
  `TRUE`.

## Value

An integer vector of the `pkill` / `Taskkill` status codes or `NULL` if
not running Java processes are found.

## Details

A list of running Java tasks is retrieved using `ps` (on Linux and
MacOS) or `tasklist` (on Windows). Tasks are killed using `pkill` (on
Linux and MacOS) or `Taskkill` (on Windows).

## Examples

``` r
# NOTE: These examples should only be run interactively or when you are
# sure that no other java processes are running simultaneously!
if (FALSE) { # \dontrun{
purge_java() # does nothing if no java processes are running

# start a new photon instance
dir <- file.path(tempdir(), "photon")
photon <- new_photon(dir, country = "Monaco")
photon$start()

# kill photon using a sledgehammer
purge_java()

photon$start()

# kill photon using a scalpel
library(ps)
p <- ps_handle(photon$proc$get_pid())
pids <- sapply(ps_children(p), ps::ps_pid)
purge_java(pids)} # }
```
