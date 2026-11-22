///|
#derive(Show, Debug)
priv suberror EmptyArrayError {
  EmptyArrayError(String)
}

///|
#derive(Show, Debug)
suberror InconsistentSeriesLength {
  InconsistentSeriesLength(String)
}

///|
#derive(Show, Debug)
priv suberror DuplicateColumnError {
  DuplicateColumnError(String)
}

///|
#derive(Show, Debug)
suberror ColumnNotFoundError {
  ColumnNotFoundError(String)
}

///|
#derive(Show, Debug)
suberror IndexOutOfBounds {
  IndexOutOfBounds(String)
}

///|
#derive(Show, Debug)
suberror InvalidType {
  InvalidType(String)
}

///|
#derive(Show, Debug)
priv suberror PathNotFound {
  PathNotFound(String)
}

///|
#derive(Show, Debug)
priv suberror NotCSVFile {
  NotCSVFile(String)
}

// suberror TypeError String derive(Show)
