connect_ <- function(
  db = "test",
  url = "mongodb://localhost",
  verbose = FALSE,
  options = mongolite::ssl_options()
) {
  # We don't actually connect but store the values
  private$con$db <- db
  private$con$url <- url
  private$con$verbose <- verbose
  private$con$options <- options
}
model_ <- function(
  name,
  schema_definition
) {
  if (missing(schema_definition)) {
    stop(
      "`schema_definition` is required"
    )
  }
  for (nm in names(schema_definition)) {
    # Whenever the transformer is not set,
    # we go for as.type()
    if (is.null(
      schema_definition[[
      nm
      ]]$transformer
    )) {
      schema_definition[[
      nm
      ]]$transformer <- get(
        sprintf(
          "as.%s",
          schema_definition[[
          nm
          ]]$type
        )
      )
    }
  }
  # Hacking our way to mimic R6
  private$model_list[[name]] <- new.env()
  # We'll be defining a new model here and returning
  # an instance of R6 based on the model.
  # The models are still listed in the mongo object.
  private$model_list[[name]]$new <- function(schema) {
    check_nms(schema, schema_definition)
    check_type(schema, schema_definition)
    R6::R6Class(
      paste0(
        tools::toTitleCase(
          name
        ),
        "Instance"
      ),
      public = list(
        save = function(quiet = TRUE) {
          con <- mongolite::mongo(
            db = private$con$db,
            collection = name,
            url = private$con$url,
            verbose = private$con$verbose,
            options = private$con$options
          )
          inserted <- con$insert(
            schema
          )
          if (quiet) {
            return(invisible(inserted))
          }
          inserted
        }
      )
    )$new()
  }
  private$model_list[[name]]$drop <- function() {
    con <- mongolite::mongo(
      db = private$con$db,
      collection = name,
      url = private$con$url,
      verbose = private$con$verbose,
      options = private$con$options
    )
    con$drop()
    con$disconnect()
  }
  private$model_list[[name]]$find <- function(...) {
    con <- mongolite::mongo(
      db = private$con$db,
      collection = name,
      url = private$con$url,
      verbose = private$con$verbose,
      options = private$con$options
    )
    search <- list(...)
    if (length(search) > 0) {
      browser()
    }
    it <- con$iterate(
      jsonlite::toJSON(
        search,
        auto_unbox = TRUE
      )
    )
    res <- list()
    while (!is.null(x <- it$one())) {
      for (i in names(x)) {
        x[[i]] <- schema_definition[[
        i
        ]]$transformer(
          x[[i]]
        )
      }
      res[[length(res) + 1]] <- x
    }
    con$disconnect()
    return(res)
  }
  private$model_list[[name]]
}


#' Mongoose
#'
#' @export
Mongoose <- R6::R6Class(
  "Mongoose",
  public = list(
    connect = connect_,
    model = model_
  ),
  private = list(
    con = list(),
    model_list = new.env()
  )
)
