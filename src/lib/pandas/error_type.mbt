///|
priv suberror EmptyArrayError {
  EmptyArrayError(String)
} derive(Show)

///|
suberror InconsistentSeriesLength {
  InconsistentSeriesLength(String)
} derive(Show)

///|
priv suberror DuplicateColumnError {
  DuplicateColumnError(String)
} derive(Show)

///|
suberror ColumnNotFoundError {
  ColumnNotFoundError(String)
} derive(Show)

///|
suberror IndexOutOfBounds {
  IndexOutOfBounds(String)
} derive(Show)

///|
suberror InvalidType {
  InvalidType(String)
} derive(Show)

///|
priv suberror PathNotFound {
  PathNotFound(String)
} derive(Show)

///|
priv suberror NotCSVFile {
  NotCSVFile(String)
} derive(Show)

// suberror TypeError String derive(Show)
