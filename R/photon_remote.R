photon_remote <- R6::R6Class(
  classname = "photon_remote",
  inherit = photon,
  public = list(
    initialize = function(url) {
      assert_url(url)
      private$url <- url
      self$mount()
      invisible(self)
    },

    get_url = function() {
      private$url
    },

    mount = function() {
      assign("instance", self, envir = photon_cache())
    }
  ),

  private = list(url = NULL)
)
