rho_session_codec_classes <- S7::new_property(
  S7::class_list,
  validator = function(value) {
    if (is.null(names(value)) || any(!nzchar(names(value)))) {
      return("must be a named class registry")
    }
    invalid <- Filter(function(class) !inherits(class, "S7_class"), value)
    if (length(invalid)) {
      "must contain only S7 class objects"
    }
  }
)

rho_jsonl_path <- S7::new_property(
  S7::class_character,
  validator = function(value) {
    if (length(value) != 1L || is.na(value) || !nzchar(value)) {
      "must be one non-empty path"
    }
  }
)

rho_jsonl_timeout <- S7::new_property(
  S7::class_integer,
  validator = function(value) {
    if (length(value) != 1L || is.na(value) || value <= 0L) {
      "must be one positive integer"
    }
  }
)

rho_session_document_storage <- S7::new_property(
  S7::class_character,
  validator = function(value) {
    supported <- c("logical", "integer", "double", "character", "raw")
    if (length(value) != 1L || is.na(value) || !value %in% supported) {
      "must name one supported R atomic storage mode"
    }
  }
)

rho_session_document_size <- S7::new_property(
  S7::class_integer,
  validator = function(value) {
    if (length(value) != 1L || is.na(value) || value < 0L) {
      "must be one non-negative integer"
    }
  }
)

rho_session_document_class <- S7::new_property(
  S7::class_character,
  validator = function(value) {
    if (length(value) != 1L || is.na(value) || !nzchar(value)) {
      "must be one non-empty S7 class key"
    }
  }
)

rho_session_property_documents <- S7::new_property(
  S7::class_list,
  validator = function(value) {
    if (length(value) && (is.null(names(value)) || any(!nzchar(names(value))))) {
      "must be a named property document list"
    }
  }
)

RhoJsonSessionCodec <- S7::new_class(
  "RhoJsonSessionCodec",
  properties = list(classes = rho_session_codec_classes)
)

RhoSessionCodecErrorValue <- S7::new_class(
  "RhoSessionCodecErrorValue",
  parent = rho.agent::RhoSessionJournalErrorValue
)

RhoJsonlSessionJournalErrorValue <- S7::new_class(
  "RhoJsonlSessionJournalErrorValue",
  parent = rho.agent::RhoSessionJournalErrorValue
)

RhoJsonlSessionJournal <- S7::new_class(
  "RhoJsonlSessionJournal",
  properties = list(
    path = rho_jsonl_path,
    codec = RhoJsonSessionCodec,
    compute = S7::class_any,
    timeout_ms = rho_jsonl_timeout
  )
)

RhoJsonSessionDocument <- S7::new_class("RhoJsonSessionDocument")

RhoJsonNullDocument <- S7::new_class(
  "RhoJsonNullDocument",
  parent = RhoJsonSessionDocument
)

RhoJsonAtomicDocument <- S7::new_class(
  "RhoJsonAtomicDocument",
  parent = RhoJsonSessionDocument,
  properties = list(
    storage = rho_session_document_storage,
    size = rho_session_document_size,
    values = S7::class_list,
    missing = S7::class_list,
    names_document = S7::class_list
  ),
  validator = function(self) {
    if (length(self@values) != self@size) {
      return("@values must have @size elements")
    }
    scalar_strings <- vapply(
      self@values,
      function(value) is.character(value) && length(value) == 1L && !is.na(value),
      logical(1)
    )
    if (!all(scalar_strings)) {
      return("@values must contain scalar strings")
    }
    values <- unlist(self@values, recursive = FALSE, use.names = FALSE)
    validators <- list(
      logical = function(value) all(value %in% c("TRUE", "FALSE")),
      integer = function(value) {
        parsed <- suppressWarnings(as.integer(value))
        all(grepl("^-?[0-9]+$", value)) && !anyNA(parsed)
      },
      double = function(value) {
        special <- value %in% c("NaN", "Inf", "-Inf")
        parsed <- suppressWarnings(as.double(value))
        all(special | (!is.na(parsed) & is.finite(parsed)))
      },
      character = function(value) TRUE,
      raw = function(value) {
        parsed <- suppressWarnings(as.integer(value))
        all(grepl("^[0-9]+$", value)) &&
          !anyNA(parsed) &&
          all(parsed >= 0L & parsed <= 255L)
      }
    )
    if (!validators[[self@storage]](values)) {
      return("@values are invalid for @storage")
    }
    missing <- unlist(self@missing, recursive = FALSE, use.names = FALSE)
    if (length(missing)) {
      positions <- suppressWarnings(as.integer(missing))
      if (
        !is.numeric(missing) ||
          anyNA(missing) ||
          anyNA(positions) ||
          any(missing != positions)
      ) {
        return("@missing must contain integer positions")
      }
      if (any(positions < 1L | positions > self@size) || anyDuplicated(positions)) {
        return("@missing positions must be unique and within @size")
      }
      if (identical(self@storage, "raw")) {
        return("raw session documents cannot contain missing positions")
      }
    }
  }
)

RhoJsonListDocument <- S7::new_class(
  "RhoJsonListDocument",
  parent = RhoJsonSessionDocument,
  properties = list(
    values = S7::class_list,
    names_document = S7::class_list
  )
)

RhoJsonS7Document <- S7::new_class(
  "RhoJsonS7Document",
  parent = RhoJsonSessionDocument,
  properties = list(
    class_key = rho_session_document_class,
    property_documents = rho_session_property_documents
  )
)

rho_encode_session_value <- S7::new_generic(
  "rho_encode_session_value",
  c("codec", "value"),
  function(codec, value, ...) S7::S7_dispatch()
)

rho_decode_session_value <- S7::new_generic(
  "rho_decode_session_value",
  c("codec", "document"),
  function(codec, document, ...) S7::S7_dispatch()
)

rho_encode_atomic_values <- S7::new_generic(
  "rho_encode_atomic_values",
  "value",
  function(value, ...) S7::S7_dispatch()
)

rho_session_codec_error <- function(message, details = list()) {
  RhoSessionCodecErrorValue(
    kind = "session_codec",
    message = message,
    retryable = FALSE,
    details = details
  )
}

rho_jsonl_session_error <- function(message, path, retryable = FALSE, details = list()) {
  RhoJsonlSessionJournalErrorValue(
    kind = "jsonl_session",
    message = message,
    retryable = retryable,
    details = c(list(path = path), details)
  )
}

rho_s7_class_key <- function(class) {
  paste0(class@package, "::", class@name)
}

rho_s7_class_descends_from <- function(class, parent) {
  parent_key <- rho_s7_class_key(parent)
  current <- class
  while (inherits(current, "S7_class")) {
    if (identical(rho_s7_class_key(current), parent_key)) {
      return(TRUE)
    }
    current <- current@parent
  }
  FALSE
}

rho_namespace_s7_classes <- function(package) {
  namespace <- asNamespace(package)
  objects <- mget(ls(namespace, all.names = TRUE), namespace, inherits = FALSE)
  classes <- Filter(function(value) inherits(value, "S7_class"), objects)
  classes[!duplicated(vapply(classes, rho_s7_class_key, character(1)))]
}

rho_derived_session_classes <- function(extra = list()) {
  candidates <- c(
    rho_namespace_s7_classes("rho.agent"),
    rho_namespace_s7_classes("rho.ai"),
    extra
  )
  keys <- vapply(candidates, rho_s7_class_key, character(1))
  candidates <- candidates[!duplicated(keys)]

  roots <- list(
    rho.agent::RhoSessionEntry,
    rho.agent::RhoCompactionReason,
    rho.agent::RhoCompactionSource,
    rho.agent::RhoCompactionOutcome,
    rho.ai::Content,
    rho.ai::UsageObservation,
    rho.ai::UsageCost,
    rho.ai::UserMessage,
    rho.ai::AssistantMessage,
    rho.ai::ToolResultMessage,
    rho.ai::WebSearchResult
  )
  roots <- c(roots, extra)

  selected <- candidates[vapply(
    candidates,
    function(class) {
      any(vapply(
        roots,
        function(root) rho_s7_class_descends_from(class, root),
        logical(1)
      ))
    },
    logical(1)
  )]

  repeat {
    property_roots <- unlist(
      lapply(selected, function(class) {
        Filter(
          function(specification) inherits(specification, "S7_class"),
          lapply(class@properties, function(property) property$class)
        )
      }),
      recursive = FALSE
    )
    expanded <- candidates[vapply(
      candidates,
      function(class) {
        any(vapply(
          property_roots,
          function(root) rho_s7_class_descends_from(class, root),
          logical(1)
        ))
      },
      logical(1)
    )]
    combined <- c(selected, expanded)
    combined_keys <- vapply(combined, rho_s7_class_key, character(1))
    combined <- combined[!duplicated(combined_keys)]
    if (length(combined) == length(selected)) {
      break
    }
    selected <- combined
  }

  selected_keys <- vapply(selected, rho_s7_class_key, character(1))
  stats::setNames(selected, selected_keys)
}

rho_json_session_codec <- function(classes = list()) {
  RhoJsonSessionCodec(classes = rho_derived_session_classes(classes))
}

rho_jsonl_session_journal <- function(
  path,
  codec = rho_json_session_codec(),
  compute = NULL,
  timeout_ms = 5000L
) {
  RhoJsonlSessionJournal(
    path = normalizePath(path.expand(path), mustWork = FALSE),
    codec = codec,
    compute = compute,
    timeout_ms = timeout_ms
  )
}

rho_encoded_names <- function(codec, value) {
  if (is.null(names(value))) {
    return(list(kind = "null"))
  }
  rho_encode_session_value(codec, unname(names(value)))
}

S7::method(rho_encode_atomic_values, S7::class_logical) <- function(value, ...) {
  encoded <- rep("FALSE", length(value))
  encoded[!is.na(value) & value] <- "TRUE"
  encoded
}

S7::method(rho_encode_atomic_values, S7::class_integer) <- function(value, ...) {
  encoded <- as.character(value)
  encoded[is.na(value)] <- "0"
  encoded
}

S7::method(rho_encode_atomic_values, S7::class_double) <- function(value, ...) {
  vapply(
    value,
    function(element) {
      if (is.nan(element)) {
        "NaN"
      } else if (is.na(element)) {
        "0"
      } else if (is.infinite(element)) {
        if (element > 0) "Inf" else "-Inf"
      } else {
        sprintf("%.17g", element)
      }
    },
    character(1)
  )
}

S7::method(rho_encode_atomic_values, S7::class_character) <- function(value, ...) {
  encoded <- value
  encoded[is.na(value)] <- ""
  encoded
}

S7::method(rho_encode_atomic_values, S7::class_raw) <- function(value, ...) {
  as.character(as.integer(value))
}

S7::method(rho_encode_atomic_values, S7::class_any) <- function(value, ...) NULL

S7::method(
  rho_encode_session_value,
  list(RhoJsonSessionCodec, S7::class_list)
) <- function(codec, value, ...) {
  if (is.object(value)) {
    return(rho_session_codec_error(
      "Only unclassed lists can be encoded as session data",
      details = list(class = class(value))
    ))
  }
  documents <- lapply(value, function(element) rho_encode_session_value(codec, element))
  invalid <- which(vapply(
    documents,
    function(document) S7::S7_inherits(document, RhoSessionCodecErrorValue),
    logical(1)
  ))
  if (length(invalid)) {
    return(documents[[invalid[[1L]]]])
  }
  encoded_names <- rho_encoded_names(codec, value)
  if (S7::S7_inherits(encoded_names, RhoSessionCodecErrorValue)) {
    return(encoded_names)
  }
  list(
    kind = "list",
    values = I(unname(documents)),
    names = encoded_names
  )
}

S7::method(
  rho_encode_session_value,
  list(RhoJsonSessionCodec, S7::S7_object)
) <- function(codec, value, ...) {
  class <- S7::S7_class(value)
  key <- rho_s7_class_key(class)
  if (!key %in% names(codec@classes)) {
    return(rho_session_codec_error(
      "The session value class is not registered",
      details = list(class = key)
    ))
  }
  properties <- lapply(
    names(class@properties),
    function(name) rho_encode_session_value(codec, S7::prop(value, name))
  )
  names(properties) <- names(class@properties)
  invalid <- which(vapply(
    properties,
    function(document) S7::S7_inherits(document, RhoSessionCodecErrorValue),
    logical(1)
  ))
  if (length(invalid)) {
    return(properties[[invalid[[1L]]]])
  }
  list(kind = "s7", class = key, properties = properties)
}

S7::method(
  rho_encode_session_value,
  list(RhoJsonSessionCodec, S7::class_any)
) <- function(codec, value, ...) {
  if (is.null(value)) {
    return(list(kind = "null"))
  }
  if (!is.atomic(value) || is.object(value)) {
    return(rho_session_codec_error(
      "The session value is not JSON-serializable",
      details = list(class = class(value), type = typeof(value))
    ))
  }
  values <- rho_encode_atomic_values(value)
  if (is.null(values)) {
    return(rho_session_codec_error(
      "The atomic session value has an unsupported storage type",
      details = list(type = typeof(value))
    ))
  }
  encoded_names <- rho_encoded_names(codec, value)
  if (S7::S7_inherits(encoded_names, RhoSessionCodecErrorValue)) {
    return(encoded_names)
  }
  list(
    kind = "atomic",
    storage = typeof(value),
    length = length(value),
    values = I(as.list(unname(values))),
    missing = I(as.list(as.integer(which(
      is.na(value) & (typeof(value) != "double" | !is.nan(value))
    )))),
    names = encoded_names
  )
}

rho_decoded_atomic_values <- function(storage, values, missing) {
  values <- unlist(values, recursive = FALSE, use.names = FALSE)
  decoders <- list(
    logical = function(value) value == "TRUE",
    integer = as.integer,
    double = as.double,
    character = as.character,
    raw = function(value) as.raw(as.integer(value))
  )
  decoded <- decoders[[storage]](values)
  if (length(missing)) {
    decoded[as.integer(unlist(missing, use.names = FALSE))] <- NA
  }
  decoded
}

rho_json_session_document <- function(document) {
  if (
    !is.list(document) ||
      length(document$kind) != 1L ||
      !is.character(document$kind) ||
      is.na(document$kind) ||
      !nzchar(document$kind)
  ) {
    return(rho_session_codec_error("The session document has no scalar kind"))
  }

  constructors <- list(
    null = function(value) RhoJsonNullDocument(),
    atomic = function(value) {
      RhoJsonAtomicDocument(
        storage = value$storage,
        size = as.integer(value$length),
        values = unname(as.list(value$values)),
        missing = unname(as.list(value$missing)),
        names_document = as.list(value$names)
      )
    },
    list = function(value) {
      RhoJsonListDocument(
        values = unname(as.list(value$values)),
        names_document = as.list(value$names)
      )
    },
    s7 = function(value) {
      RhoJsonS7Document(
        class_key = value$class,
        property_documents = as.list(value$properties)
      )
    }
  )
  constructor <- constructors[[document$kind]]
  if (is.null(constructor)) {
    return(rho_session_codec_error(
      "The session document kind is unsupported",
      details = list(kind = document$kind)
    ))
  }
  tryCatch(
    constructor(document),
    error = function(error) {
      rho_session_codec_error(
        "The session document is invalid",
        details = list(kind = document$kind, message = conditionMessage(error))
      )
    }
  )
}

rho_session_codec_first_error <- function(values) {
  invalid <- which(vapply(
    values,
    function(value) S7::S7_inherits(value, RhoSessionCodecErrorValue),
    logical(1)
  ))
  if (length(invalid)) values[[invalid[[1L]]]] else NULL
}

rho_session_document_names <- function(codec, document, size, description) {
  decoded <- rho_decode_session_value(codec, document)
  if (S7::S7_inherits(decoded, RhoSessionCodecErrorValue)) {
    return(decoded)
  }
  if (!is.null(decoded) && length(decoded) != size) {
    return(rho_session_codec_error(
      paste("The", description, "session document has invalid names")
    ))
  }
  decoded
}

S7::method(
  rho_decode_session_value,
  list(RhoJsonSessionCodec, S7::class_list)
) <- function(
  codec,
  document,
  ...
) {
  normalized <- rho_json_session_document(document)
  if (S7::S7_inherits(normalized, RhoSessionCodecErrorValue)) {
    return(normalized)
  }
  rho_decode_session_value(codec, normalized)
}

S7::method(
  rho_decode_session_value,
  list(RhoJsonSessionCodec, S7::class_any)
) <- function(codec, document, ...) {
  rho_session_codec_error(
    "The session document must be a JSON object or typed JSON session document",
    details = list(class = class(document), type = typeof(document))
  )
}

S7::method(
  rho_decode_session_value,
  list(RhoJsonSessionCodec, RhoJsonNullDocument)
) <- function(codec, document, ...) NULL

S7::method(
  rho_decode_session_value,
  list(RhoJsonSessionCodec, RhoJsonAtomicDocument)
) <- function(codec, document, ...) {
  decoded <- rho_decoded_atomic_values(
    document@storage,
    document@values,
    document@missing
  )
  decoded_names <- rho_session_document_names(
    codec,
    document@names_document,
    document@size,
    "atomic"
  )
  if (S7::S7_inherits(decoded_names, RhoSessionCodecErrorValue)) {
    return(decoded_names)
  }
  if (!is.null(decoded_names)) {
    names(decoded) <- decoded_names
  }
  decoded
}

S7::method(
  rho_decode_session_value,
  list(RhoJsonSessionCodec, RhoJsonListDocument)
) <- function(codec, document, ...) {
  decoded <- lapply(
    document@values,
    function(value) rho_decode_session_value(codec, value)
  )
  invalid <- rho_session_codec_first_error(decoded)
  if (!is.null(invalid)) {
    return(invalid)
  }
  decoded_names <- rho_session_document_names(
    codec,
    document@names_document,
    length(decoded),
    "list"
  )
  if (S7::S7_inherits(decoded_names, RhoSessionCodecErrorValue)) {
    return(decoded_names)
  }
  if (!is.null(decoded_names)) {
    names(decoded) <- decoded_names
  }
  decoded
}

S7::method(
  rho_decode_session_value,
  list(RhoJsonSessionCodec, RhoJsonS7Document)
) <- function(codec, document, ...) {
  if (!document@class_key %in% names(codec@classes)) {
    return(rho_session_codec_error(
      "The S7 session document names an unregistered class",
      details = list(class = document@class_key)
    ))
  }
  class <- codec@classes[[document@class_key]]
  expected <- names(class@properties)
  if (!setequal(names(document@property_documents), expected)) {
    return(rho_session_codec_error(
      "The S7 session document properties do not match its class",
      details = list(class = document@class_key)
    ))
  }
  properties <- lapply(
    document@property_documents[expected],
    function(value) rho_decode_session_value(codec, value)
  )
  invalid <- rho_session_codec_first_error(properties)
  if (!is.null(invalid)) {
    return(invalid)
  }
  tryCatch(
    do.call(class, properties),
    error = function(error) {
      rho_session_codec_error(
        "The S7 session document failed class validation",
        details = list(class = document@class_key, message = conditionMessage(error))
      )
    }
  )
}

rho_jsonl_record_line <- function(codec, entry, position) {
  document <- rho_encode_session_value(codec, entry)
  if (S7::S7_inherits(document, RhoSessionCodecErrorValue)) {
    return(document)
  }
  yyjsonr::write_json_str(
    list(
      schema = "rho.session.jsonl",
      version = 1L,
      position = position,
      entry = document
    ),
    auto_unbox = TRUE,
    null = "null",
    digits = -1L
  )
}

rho_jsonl_inspect_file <- function(path) {
  tryCatch(
    {
      if (!file.exists(path)) {
        return(list(status = "ok", position = 0L, entries = list()))
      }
      size <- file.info(path)$size
      if (is.na(size) || size > .Machine$integer.max) {
        return(list(status = "corrupt", message = "The JSONL journal size is invalid"))
      }
      if (size == 0) {
        return(list(status = "ok", position = 0L, entries = list()))
      }
      connection <- file(path, open = "rb")
      on.exit(close(connection), add = TRUE)
      bytes <- readBin(connection, what = "raw", n = as.integer(size))
      if (!identical(bytes[[length(bytes)]], as.raw(10L))) {
        return(list(status = "corrupt", message = "The JSONL journal ends with a partial line"))
      }
      text <- rawToChar(bytes[-length(bytes)])
      if (!nzchar(text) || startsWith(text, "\n") || endsWith(text, "\n")) {
        return(list(status = "corrupt", message = "The JSONL journal contains an empty line"))
      }
      lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
      if (any(!nzchar(lines))) {
        return(list(status = "corrupt", message = "The JSONL journal contains an empty line"))
      }
      entries <- vector("list", length(lines))
      for (index in seq_along(lines)) {
        if (endsWith(lines[[index]], "\r")) {
          return(list(status = "corrupt", message = "The JSONL journal must use LF framing"))
        }
        record <- tryCatch(
          yyjsonr::read_json_str(
            lines[[index]],
            arr_of_objs_to_df = FALSE,
            obj_of_arrs_to_df = FALSE
          ),
          error = function(error) error
        )
        if (inherits(record, "error")) {
          return(list(
            status = "corrupt",
            message = sprintf("JSONL line %d is not valid JSON", index)
          ))
        }
        valid <- is.list(record) &&
          identical(record$schema, "rho.session.jsonl") &&
          identical(as.integer(record$version), 1L) &&
          identical(as.integer(record$position), as.integer(index)) &&
          is.list(record$entry)
        if (!valid) {
          return(list(
            status = "corrupt",
            message = sprintf("JSONL line %d has an invalid session record", index)
          ))
        }
        entries[[index]] <- record$entry
      }
      list(status = "ok", position = as.integer(length(entries)), entries = entries)
    },
    error = function(error) {
      list(status = "io_error", message = conditionMessage(error))
    }
  )
}

rho_jsonl_snapshot_worker <- function(path, inspect) {
  inspect(path)
}

rho_jsonl_commit_worker <- function(path, line, after, timeout_ms, inspect) {
  tryCatch(
    {
      directory <- dirname(path)
      if (!dir.exists(directory)) {
        dir.create(directory, recursive = TRUE, showWarnings = FALSE)
      }
      lock <- filelock::lock(paste0(path, ".lock"), timeout = timeout_ms)
      if (is.null(lock)) {
        return(list(status = "locked", message = "The JSONL journal lock timed out"))
      }
      on.exit(filelock::unlock(lock), add = TRUE)

      inspected <- inspect(path)
      if (!identical(inspected$status, "ok")) {
        return(inspected)
      }
      if (!identical(inspected$position, after)) {
        return(list(
          status = "conflict",
          expected = after,
          current = inspected$position
        ))
      }

      record <- yyjsonr::read_json_str(
        line,
        arr_of_objs_to_df = FALSE,
        obj_of_arrs_to_df = FALSE
      )
      if (!identical(as.integer(record$position), after + 1L)) {
        return(list(status = "io_error", message = "The append record position is invalid"))
      }
      connection <- file(path, open = "ab")
      on.exit(
        {
          if (!is.null(connection)) {
            close(connection)
          }
        },
        add = TRUE
      )
      writeBin(c(charToRaw(line), as.raw(10L)), connection)
      flush(connection)
      close(connection)
      connection <- NULL
      Sys.chmod(path, mode = "0600")
      list(status = "committed", position = after + 1L)
    },
    error = function(error) {
      list(status = "io_error", message = conditionMessage(error))
    }
  )
}

rho_jsonl_worker_error <- function(result, journal) {
  if (S7::S7_inherits(result, rho.compute::RhoComputeErrorValue)) {
    return(rho_jsonl_session_error(
      result@message,
      journal@path,
      retryable = TRUE,
      details = list(source = result@source)
    ))
  }
  if (!is.list(result) || length(result$status) != 1L) {
    return(rho_jsonl_session_error(
      "The JSONL journal worker returned an invalid result",
      journal@path
    ))
  }
  if (identical(result$status, "conflict")) {
    return(rho.agent::rho_session_conflict(
      "The JSONL session journal has advanced beyond the expected position",
      details = list(
        path = journal@path,
        expected = result$expected,
        current = result$current
      )
    ))
  }
  rho_jsonl_session_error(
    result$message,
    journal@path,
    retryable = identical(result$status, "locked"),
    details = list(status = result$status)
  )
}

S7::method(
  rho_commit_session_entry,
  list(RhoJsonlSessionJournal, rho.agent::RhoSessionAppend)
) <- function(journal, append, ...) {
  line <- rho_jsonl_record_line(
    journal@codec,
    append@entry,
    append@after + 1L
  )
  if (S7::S7_inherits(line, RhoSessionCodecErrorValue)) {
    return(rho.async::rho_task(line))
  }
  task <- rho.compute::rho_mirai_call(
    rho_jsonl_commit_worker,
    args = list(
      path = journal@path,
      line = line,
      after = append@after,
      timeout_ms = journal@timeout_ms,
      inspect = rho_jsonl_inspect_file
    ),
    timeout_ms = journal@timeout_ms,
    compute = journal@compute
  )
  rho.async::rho_then(task, function(result) {
    if (!is.list(result) || !identical(result$status, "committed")) {
      return(rho_jsonl_worker_error(result, journal))
    }
    rho.agent::RhoSessionCommit(
      entry = append@entry,
      position = as.integer(result$position)
    )
  })
}

S7::method(
  rho_session_snapshot,
  RhoJsonlSessionJournal
) <- function(journal, ...) {
  task <- rho.compute::rho_mirai_call(
    rho_jsonl_snapshot_worker,
    args = list(path = journal@path, inspect = rho_jsonl_inspect_file),
    timeout_ms = journal@timeout_ms,
    compute = journal@compute
  )
  rho.async::rho_then(task, function(result) {
    if (!is.list(result) || !identical(result$status, "ok")) {
      return(rho_jsonl_worker_error(result, journal))
    }
    entries <- lapply(
      result$entries,
      function(document) rho_decode_session_value(journal@codec, document)
    )
    invalid <- which(vapply(
      entries,
      function(entry) S7::S7_inherits(entry, RhoSessionCodecErrorValue),
      logical(1)
    ))
    if (length(invalid)) {
      return(entries[[invalid[[1L]]]])
    }
    tryCatch(
      rho.agent::RhoSessionSnapshot(
        entries = entries,
        position = as.integer(result$position)
      ),
      error = function(error) {
        rho_jsonl_session_error(
          "The JSONL journal does not form a valid session snapshot",
          journal@path,
          details = list(message = conditionMessage(error))
        )
      }
    )
  })
}
