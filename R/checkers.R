check_nms <- function(
  schema,
  schema_definition
) {
  all_nms <- all(
    names(schema) %in% names(schema_definition)
  )
  if (!all_nms) {
    stop(
      "[Undefined Entry] All elements should be defined in the data model",
      call. = FALSE
    )
  }
}

check_type <- function(
  schema,
  schema_definition
) {
  for (i in seq_along(schema)) {
    nm <- names(schema)[i]
    inht <- inherits(
      schema[[nm]],
      schema_definition[[
      nm
      ]]$type
    )
    if (!inht) {
      stop(
        sprintf(
          "[Bad Type] %s does not inherits from %s",
          nm,
          schema_definition[[
          nm
          ]]$type
        ),
        call. = FALSE
      )
    }
  }
}

