// 由 docs/golden/scripts/cast.py 生成，勿手改

///|
let golden_cast : String =
  #|[
  #| {
  #|  "from": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "true",
  #|    "false",
  #|    null
  #|   ]
  #|  },
  #|  "id": "bool->bool/strict",
  #|  "result": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "true",
  #|    "false",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "bool"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "true",
  #|    "false",
  #|    null
  #|   ]
  #|  },
  #|  "id": "bool->bool/lenient",
  #|  "result": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "true",
  #|    "false",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "bool"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "true",
  #|    "false",
  #|    null
  #|   ]
  #|  },
  #|  "id": "bool->i32/strict",
  #|  "result": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "i32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "true",
  #|    "false",
  #|    null
  #|   ]
  #|  },
  #|  "id": "bool->i32/lenient",
  #|  "result": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "i32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "true",
  #|    "false",
  #|    null
  #|   ]
  #|  },
  #|  "id": "bool->i64/strict",
  #|  "result": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "i64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "true",
  #|    "false",
  #|    null
  #|   ]
  #|  },
  #|  "id": "bool->i64/lenient",
  #|  "result": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "i64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "true",
  #|    "false",
  #|    null
  #|   ]
  #|  },
  #|  "id": "bool->f32/strict",
  #|  "result": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "1.0",
  #|    "0.0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "f32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "true",
  #|    "false",
  #|    null
  #|   ]
  #|  },
  #|  "id": "bool->f32/lenient",
  #|  "result": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "1.0",
  #|    "0.0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "f32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "true",
  #|    "false",
  #|    null
  #|   ]
  #|  },
  #|  "id": "bool->f64/strict",
  #|  "result": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "1.0",
  #|    "0.0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "f64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "true",
  #|    "false",
  #|    null
  #|   ]
  #|  },
  #|  "id": "bool->f64/lenient",
  #|  "result": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "1.0",
  #|    "0.0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "f64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "true",
  #|    "false",
  #|    null
  #|   ]
  #|  },
  #|  "id": "bool->str/strict",
  #|  "result": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "true",
  #|    "false",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "str"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "true",
  #|    "false",
  #|    null
  #|   ]
  #|  },
  #|  "id": "bool->str/lenient",
  #|  "result": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "true",
  #|    "false",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "str"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "true",
  #|    "false",
  #|    null
  #|   ]
  #|  },
  #|  "id": "bool->date/strict",
  #|  "result": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "date"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "true",
  #|    "false",
  #|    null
  #|   ]
  #|  },
  #|  "id": "bool->date/lenient",
  #|  "result": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "date"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "true",
  #|    "false",
  #|    null
  #|   ]
  #|  },
  #|  "id": "bool->datetime[μs]/strict",
  #|  "result": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "datetime[μs]"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "true",
  #|    "false",
  #|    null
  #|   ]
  #|  },
  #|  "id": "bool->datetime[μs]/lenient",
  #|  "result": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "datetime[μs]"
  #| },
  #| {
  #|  "error": "ComputeError",
  #|  "from": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "true",
  #|    "false",
  #|    null
  #|   ]
  #|  },
  #|  "id": "bool->null/strict",
  #|  "polars_error": "InvalidOperationError: conversion from `bool` to `null` failed in column 'a' for 2 out of 3 values: [true, false]",
  #|  "strict": true,
  #|  "to": "null"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "true",
  #|    "false",
  #|    null
  #|   ]
  #|  },
  #|  "id": "bool->null/lenient",
  #|  "result": {
  #|   "dtype": "null",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "null"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i32->bool/strict",
  #|  "result": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "false",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "bool"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i32->bool/lenient",
  #|  "result": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "false",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "bool"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i32->i32/strict",
  #|  "result": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "i32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i32->i32/lenient",
  #|  "result": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "i32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i32->i64/strict",
  #|  "result": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "i64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i32->i64/lenient",
  #|  "result": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "i64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i32->f32/strict",
  #|  "result": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "1.0",
  #|    "-1.0",
  #|    "2147483648.0",
  #|    "-2147483648.0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "f32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i32->f32/lenient",
  #|  "result": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "1.0",
  #|    "-1.0",
  #|    "2147483648.0",
  #|    "-2147483648.0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "f32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i32->f64/strict",
  #|  "result": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "1.0",
  #|    "-1.0",
  #|    "2147483647.0",
  #|    "-2147483648.0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "f64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i32->f64/lenient",
  #|  "result": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "1.0",
  #|    "-1.0",
  #|    "2147483647.0",
  #|    "-2147483648.0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "f64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i32->str/strict",
  #|  "result": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "str"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i32->str/lenient",
  #|  "result": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "str"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i32->date/strict",
  #|  "result": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "date"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i32->date/lenient",
  #|  "result": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "date"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i32->datetime[μs]/strict",
  #|  "result": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "datetime[μs]"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i32->datetime[μs]/lenient",
  #|  "result": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "datetime[μs]"
  #| },
  #| {
  #|  "error": "ComputeError",
  #|  "from": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i32->null/strict",
  #|  "polars_error": "InvalidOperationError: conversion from `i32` to `null` failed in column 'a' for 5 out of 6 values: [0, 1, … -2147483648]",
  #|  "strict": true,
  #|  "to": "null"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483647",
  #|    "-2147483648",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i32->null/lenient",
  #|  "result": {
  #|   "dtype": "null",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "null"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483648",
  #|    "9223372036854775807",
  #|    "-9223372036854775808",
  #|    "-2147483648",
  #|    "2147483647",
  #|    "2147483649",
  #|    "-2147483649",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i64->bool/strict",
  #|  "result": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "false",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "bool"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483648",
  #|    "9223372036854775807",
  #|    "-9223372036854775808",
  #|    "-2147483648",
  #|    "2147483647",
  #|    "2147483649",
  #|    "-2147483649",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i64->bool/lenient",
  #|  "result": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "false",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "bool"
  #| },
  #| {
  #|  "error": "ComputeError",
  #|  "from": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483648",
  #|    "9223372036854775807",
  #|    "-9223372036854775808",
  #|    "-2147483648",
  #|    "2147483647",
  #|    "2147483649",
  #|    "-2147483649",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i64->i32/strict",
  #|  "polars_error": "InvalidOperationError: conversion from `i64` to `i32` failed in column 'a' for 5 out of 11 values: [2147483648, 9223372036854775807, … -2147483649]",
  #|  "strict": true,
  #|  "to": "i32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483648",
  #|    "9223372036854775807",
  #|    "-9223372036854775808",
  #|    "-2147483648",
  #|    "2147483647",
  #|    "2147483649",
  #|    "-2147483649",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i64->i32/lenient",
  #|  "result": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    null,
  #|    null,
  #|    null,
  #|    "-2147483648",
  #|    "2147483647",
  #|    null,
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "i32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483648",
  #|    "9223372036854775807",
  #|    "-9223372036854775808",
  #|    "-2147483648",
  #|    "2147483647",
  #|    "2147483649",
  #|    "-2147483649",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i64->i64/strict",
  #|  "result": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483648",
  #|    "9223372036854775807",
  #|    "-9223372036854775808",
  #|    "-2147483648",
  #|    "2147483647",
  #|    "2147483649",
  #|    "-2147483649",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "i64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483648",
  #|    "9223372036854775807",
  #|    "-9223372036854775808",
  #|    "-2147483648",
  #|    "2147483647",
  #|    "2147483649",
  #|    "-2147483649",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i64->i64/lenient",
  #|  "result": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483648",
  #|    "9223372036854775807",
  #|    "-9223372036854775808",
  #|    "-2147483648",
  #|    "2147483647",
  #|    "2147483649",
  #|    "-2147483649",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "i64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483648",
  #|    "9223372036854775807",
  #|    "-9223372036854775808",
  #|    "-2147483648",
  #|    "2147483647",
  #|    "2147483649",
  #|    "-2147483649",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i64->f32/strict",
  #|  "result": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "1.0",
  #|    "-1.0",
  #|    "2147483648.0",
  #|    "9.223372036854776e+18",
  #|    "-9.223372036854776e+18",
  #|    "-2147483648.0",
  #|    "2147483648.0",
  #|    "2147483648.0",
  #|    "-2147483648.0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "f32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483648",
  #|    "9223372036854775807",
  #|    "-9223372036854775808",
  #|    "-2147483648",
  #|    "2147483647",
  #|    "2147483649",
  #|    "-2147483649",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i64->f32/lenient",
  #|  "result": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "1.0",
  #|    "-1.0",
  #|    "2147483648.0",
  #|    "9.223372036854776e+18",
  #|    "-9.223372036854776e+18",
  #|    "-2147483648.0",
  #|    "2147483648.0",
  #|    "2147483648.0",
  #|    "-2147483648.0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "f32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483648",
  #|    "9223372036854775807",
  #|    "-9223372036854775808",
  #|    "-2147483648",
  #|    "2147483647",
  #|    "2147483649",
  #|    "-2147483649",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i64->f64/strict",
  #|  "result": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "1.0",
  #|    "-1.0",
  #|    "2147483648.0",
  #|    "9.223372036854776e+18",
  #|    "-9.223372036854776e+18",
  #|    "-2147483648.0",
  #|    "2147483647.0",
  #|    "2147483649.0",
  #|    "-2147483649.0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "f64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483648",
  #|    "9223372036854775807",
  #|    "-9223372036854775808",
  #|    "-2147483648",
  #|    "2147483647",
  #|    "2147483649",
  #|    "-2147483649",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i64->f64/lenient",
  #|  "result": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "1.0",
  #|    "-1.0",
  #|    "2147483648.0",
  #|    "9.223372036854776e+18",
  #|    "-9.223372036854776e+18",
  #|    "-2147483648.0",
  #|    "2147483647.0",
  #|    "2147483649.0",
  #|    "-2147483649.0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "f64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483648",
  #|    "9223372036854775807",
  #|    "-9223372036854775808",
  #|    "-2147483648",
  #|    "2147483647",
  #|    "2147483649",
  #|    "-2147483649",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i64->str/strict",
  #|  "result": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483648",
  #|    "9223372036854775807",
  #|    "-9223372036854775808",
  #|    "-2147483648",
  #|    "2147483647",
  #|    "2147483649",
  #|    "-2147483649",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "str"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483648",
  #|    "9223372036854775807",
  #|    "-9223372036854775808",
  #|    "-2147483648",
  #|    "2147483647",
  #|    "2147483649",
  #|    "-2147483649",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i64->str/lenient",
  #|  "result": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483648",
  #|    "9223372036854775807",
  #|    "-9223372036854775808",
  #|    "-2147483648",
  #|    "2147483647",
  #|    "2147483649",
  #|    "-2147483649",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "str"
  #| },
  #| {
  #|  "error": "ComputeError",
  #|  "from": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483648",
  #|    "9223372036854775807",
  #|    "-9223372036854775808",
  #|    "-2147483648",
  #|    "2147483647",
  #|    "2147483649",
  #|    "-2147483649",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i64->date/strict",
  #|  "polars_error": "InvalidOperationError: conversion from `i64` to `date` failed in column 'a' for 5 out of 11 values: [2147483648, 9223372036854775807, … -2147483649]",
  #|  "strict": true,
  #|  "to": "date"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483648",
  #|    "9223372036854775807",
  #|    "-9223372036854775808",
  #|    "-2147483648",
  #|    "2147483647",
  #|    "2147483649",
  #|    "-2147483649",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i64->date/lenient",
  #|  "result": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    null,
  #|    null,
  #|    null,
  #|    "-2147483648",
  #|    "2147483647",
  #|    null,
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "date"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483648",
  #|    "9223372036854775807",
  #|    "-9223372036854775808",
  #|    "-2147483648",
  #|    "2147483647",
  #|    "2147483649",
  #|    "-2147483649",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i64->datetime[μs]/strict",
  #|  "result": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483648",
  #|    "9223372036854775807",
  #|    "-9223372036854775808",
  #|    "-2147483648",
  #|    "2147483647",
  #|    "2147483649",
  #|    "-2147483649",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "datetime[μs]"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483648",
  #|    "9223372036854775807",
  #|    "-9223372036854775808",
  #|    "-2147483648",
  #|    "2147483647",
  #|    "2147483649",
  #|    "-2147483649",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i64->datetime[μs]/lenient",
  #|  "result": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483648",
  #|    "9223372036854775807",
  #|    "-9223372036854775808",
  #|    "-2147483648",
  #|    "2147483647",
  #|    "2147483649",
  #|    "-2147483649",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "datetime[μs]"
  #| },
  #| {
  #|  "error": "ComputeError",
  #|  "from": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483648",
  #|    "9223372036854775807",
  #|    "-9223372036854775808",
  #|    "-2147483648",
  #|    "2147483647",
  #|    "2147483649",
  #|    "-2147483649",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i64->null/strict",
  #|  "polars_error": "InvalidOperationError: conversion from `i64` to `null` failed in column 'a' for 10 out of 11 values: [0, 1, … -2147483649]",
  #|  "strict": true,
  #|  "to": "null"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    "2147483648",
  #|    "9223372036854775807",
  #|    "-9223372036854775808",
  #|    "-2147483648",
  #|    "2147483647",
  #|    "2147483649",
  #|    "-2147483649",
  #|    null
  #|   ]
  #|  },
  #|  "id": "i64->null/lenient",
  #|  "result": {
  #|   "dtype": "null",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "null"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-1.5",
  #|    "3.3999999521443642e+38",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f32->bool/strict",
  #|  "result": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "false",
  #|    "false",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "bool"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-1.5",
  #|    "3.3999999521443642e+38",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f32->bool/lenient",
  #|  "result": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "false",
  #|    "false",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "bool"
  #| },
  #| {
  #|  "error": "ComputeError",
  #|  "from": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-1.5",
  #|    "3.3999999521443642e+38",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f32->i32/strict",
  #|  "polars_error": "InvalidOperationError: conversion from `f32` to `i32` failed in column 'a' for 4 out of 9 values: [3.4000e38, NaN, … -inf]",
  #|  "strict": true,
  #|  "to": "i32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-1.5",
  #|    "3.3999999521443642e+38",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f32->i32/lenient",
  #|  "result": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "i32"
  #| },
  #| {
  #|  "error": "ComputeError",
  #|  "from": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-1.5",
  #|    "3.3999999521443642e+38",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f32->i64/strict",
  #|  "polars_error": "InvalidOperationError: conversion from `f32` to `i64` failed in column 'a' for 4 out of 9 values: [3.4000e38, NaN, … -inf]",
  #|  "strict": true,
  #|  "to": "i64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-1.5",
  #|    "3.3999999521443642e+38",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f32->i64/lenient",
  #|  "result": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "i64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-1.5",
  #|    "3.3999999521443642e+38",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f32->f32/strict",
  #|  "result": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-1.5",
  #|    "3.3999999521443642e+38",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "f32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-1.5",
  #|    "3.3999999521443642e+38",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f32->f32/lenient",
  #|  "result": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-1.5",
  #|    "3.3999999521443642e+38",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "f32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-1.5",
  #|    "3.3999999521443642e+38",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f32->f64/strict",
  #|  "result": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-1.5",
  #|    "3.3999999521443642e+38",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "f64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-1.5",
  #|    "3.3999999521443642e+38",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f32->f64/lenient",
  #|  "result": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-1.5",
  #|    "3.3999999521443642e+38",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "f64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-1.5",
  #|    "3.3999999521443642e+38",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f32->str/strict",
  #|  "result": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-1.5",
  #|    "3.4e+38",
  #|    "NaN",
  #|    "inf",
  #|    "-inf",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "str"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-1.5",
  #|    "3.3999999521443642e+38",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f32->str/lenient",
  #|  "result": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-1.5",
  #|    "3.4e+38",
  #|    "NaN",
  #|    "inf",
  #|    "-inf",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "str"
  #| },
  #| {
  #|  "error": "ComputeError",
  #|  "from": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-1.5",
  #|    "3.3999999521443642e+38",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f32->date/strict",
  #|  "polars_error": "InvalidOperationError: conversion from `f32` to `date` failed in column 'a' for 4 out of 9 values: [3.4000e38, NaN, … -inf]",
  #|  "strict": true,
  #|  "to": "date"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-1.5",
  #|    "3.3999999521443642e+38",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f32->date/lenient",
  #|  "result": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "date"
  #| },
  #| {
  #|  "error": "ComputeError",
  #|  "from": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-1.5",
  #|    "3.3999999521443642e+38",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f32->datetime[μs]/strict",
  #|  "polars_error": "InvalidOperationError: conversion from `f32` to `datetime[μs]` failed in column 'a' for 4 out of 9 values: [3.4000e38, NaN, … -inf]",
  #|  "strict": true,
  #|  "to": "datetime[μs]"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-1.5",
  #|    "3.3999999521443642e+38",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f32->datetime[μs]/lenient",
  #|  "result": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "0",
  #|    "1",
  #|    "-1",
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "datetime[μs]"
  #| },
  #| {
  #|  "error": "ComputeError",
  #|  "from": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-1.5",
  #|    "3.3999999521443642e+38",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f32->null/strict",
  #|  "polars_error": "InvalidOperationError: conversion from `f32` to `null` failed in column 'a' for 8 out of 9 values: [0.0, -0.0, … -inf]",
  #|  "strict": true,
  #|  "to": "null"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-1.5",
  #|    "3.3999999521443642e+38",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f32->null/lenient",
  #|  "result": {
  #|   "dtype": "null",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "null"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-2.5",
  #|    "0.1",
  #|    "1e+20",
  #|    "1e+300",
  #|    "123456789.125",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    "-2147483648.0",
  #|    "-2147483649.0",
  #|    "2147483647.0",
  #|    "2147483648.0",
  #|    "-9.223372036854776e+18",
  #|    "9.223372036854776e+18",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f64->bool/strict",
  #|  "result": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "false",
  #|    "false",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "bool"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-2.5",
  #|    "0.1",
  #|    "1e+20",
  #|    "1e+300",
  #|    "123456789.125",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    "-2147483648.0",
  #|    "-2147483649.0",
  #|    "2147483647.0",
  #|    "2147483648.0",
  #|    "-9.223372036854776e+18",
  #|    "9.223372036854776e+18",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f64->bool/lenient",
  #|  "result": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    "false",
  #|    "false",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    "true",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "bool"
  #| },
  #| {
  #|  "error": "ComputeError",
  #|  "from": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-2.5",
  #|    "0.1",
  #|    "1e+20",
  #|    "1e+300",
  #|    "123456789.125",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    "-2147483648.0",
  #|    "-2147483649.0",
  #|    "2147483647.0",
  #|    "2147483648.0",
  #|    "-9.223372036854776e+18",
  #|    "9.223372036854776e+18",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f64->i32/strict",
  #|  "polars_error": "InvalidOperationError: conversion from `f64` to `i32` failed in column 'a' for 9 out of 18 values: [1.0000e20, 1.0000e300, … 9.2234e18]",
  #|  "strict": true,
  #|  "to": "i32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-2.5",
  #|    "0.1",
  #|    "1e+20",
  #|    "1e+300",
  #|    "123456789.125",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    "-2147483648.0",
  #|    "-2147483649.0",
  #|    "2147483647.0",
  #|    "2147483648.0",
  #|    "-9.223372036854776e+18",
  #|    "9.223372036854776e+18",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f64->i32/lenient",
  #|  "result": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "0",
  #|    "1",
  #|    "-2",
  #|    "0",
  #|    null,
  #|    null,
  #|    "123456789",
  #|    null,
  #|    null,
  #|    null,
  #|    "-2147483648",
  #|    null,
  #|    "2147483647",
  #|    null,
  #|    null,
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "i32"
  #| },
  #| {
  #|  "error": "ComputeError",
  #|  "from": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-2.5",
  #|    "0.1",
  #|    "1e+20",
  #|    "1e+300",
  #|    "123456789.125",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    "-2147483648.0",
  #|    "-2147483649.0",
  #|    "2147483647.0",
  #|    "2147483648.0",
  #|    "-9.223372036854776e+18",
  #|    "9.223372036854776e+18",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f64->i64/strict",
  #|  "polars_error": "InvalidOperationError: conversion from `f64` to `i64` failed in column 'a' for 6 out of 18 values: [1.0000e20, 1.0000e300, … 9.2234e18]",
  #|  "strict": true,
  #|  "to": "i64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-2.5",
  #|    "0.1",
  #|    "1e+20",
  #|    "1e+300",
  #|    "123456789.125",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    "-2147483648.0",
  #|    "-2147483649.0",
  #|    "2147483647.0",
  #|    "2147483648.0",
  #|    "-9.223372036854776e+18",
  #|    "9.223372036854776e+18",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f64->i64/lenient",
  #|  "result": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "0",
  #|    "1",
  #|    "-2",
  #|    "0",
  #|    null,
  #|    null,
  #|    "123456789",
  #|    null,
  #|    null,
  #|    null,
  #|    "-2147483648",
  #|    "-2147483649",
  #|    "2147483647",
  #|    "2147483648",
  #|    "-9223372036854775808",
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "i64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-2.5",
  #|    "0.1",
  #|    "1e+20",
  #|    "1e+300",
  #|    "123456789.125",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    "-2147483648.0",
  #|    "-2147483649.0",
  #|    "2147483647.0",
  #|    "2147483648.0",
  #|    "-9.223372036854776e+18",
  #|    "9.223372036854776e+18",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f64->f32/strict",
  #|  "result": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-2.5",
  #|    "0.10000000149011612",
  #|    "1.0000000200408773e+20",
  #|    "inf",
  #|    "123456792.0",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    "-2147483648.0",
  #|    "-2147483648.0",
  #|    "2147483648.0",
  #|    "2147483648.0",
  #|    "-9.223372036854776e+18",
  #|    "9.223372036854776e+18",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "f32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-2.5",
  #|    "0.1",
  #|    "1e+20",
  #|    "1e+300",
  #|    "123456789.125",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    "-2147483648.0",
  #|    "-2147483649.0",
  #|    "2147483647.0",
  #|    "2147483648.0",
  #|    "-9.223372036854776e+18",
  #|    "9.223372036854776e+18",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f64->f32/lenient",
  #|  "result": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-2.5",
  #|    "0.10000000149011612",
  #|    "1.0000000200408773e+20",
  #|    "inf",
  #|    "123456792.0",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    "-2147483648.0",
  #|    "-2147483648.0",
  #|    "2147483648.0",
  #|    "2147483648.0",
  #|    "-9.223372036854776e+18",
  #|    "9.223372036854776e+18",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "f32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-2.5",
  #|    "0.1",
  #|    "1e+20",
  #|    "1e+300",
  #|    "123456789.125",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    "-2147483648.0",
  #|    "-2147483649.0",
  #|    "2147483647.0",
  #|    "2147483648.0",
  #|    "-9.223372036854776e+18",
  #|    "9.223372036854776e+18",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f64->f64/strict",
  #|  "result": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-2.5",
  #|    "0.1",
  #|    "1e+20",
  #|    "1e+300",
  #|    "123456789.125",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    "-2147483648.0",
  #|    "-2147483649.0",
  #|    "2147483647.0",
  #|    "2147483648.0",
  #|    "-9.223372036854776e+18",
  #|    "9.223372036854776e+18",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "f64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-2.5",
  #|    "0.1",
  #|    "1e+20",
  #|    "1e+300",
  #|    "123456789.125",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    "-2147483648.0",
  #|    "-2147483649.0",
  #|    "2147483647.0",
  #|    "2147483648.0",
  #|    "-9.223372036854776e+18",
  #|    "9.223372036854776e+18",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f64->f64/lenient",
  #|  "result": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-2.5",
  #|    "0.1",
  #|    "1e+20",
  #|    "1e+300",
  #|    "123456789.125",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    "-2147483648.0",
  #|    "-2147483649.0",
  #|    "2147483647.0",
  #|    "2147483648.0",
  #|    "-9.223372036854776e+18",
  #|    "9.223372036854776e+18",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "f64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-2.5",
  #|    "0.1",
  #|    "1e+20",
  #|    "1e+300",
  #|    "123456789.125",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    "-2147483648.0",
  #|    "-2147483649.0",
  #|    "2147483647.0",
  #|    "2147483648.0",
  #|    "-9.223372036854776e+18",
  #|    "9.223372036854776e+18",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f64->str/strict",
  #|  "result": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-2.5",
  #|    "0.1",
  #|    "1e+20",
  #|    "1e+300",
  #|    "123456789.125",
  #|    "NaN",
  #|    "inf",
  #|    "-inf",
  #|    "-2147483648.0",
  #|    "-2147483649.0",
  #|    "2147483647.0",
  #|    "2147483648.0",
  #|    "-9.223372036854776e+18",
  #|    "9.223372036854776e+18",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "str"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-2.5",
  #|    "0.1",
  #|    "1e+20",
  #|    "1e+300",
  #|    "123456789.125",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    "-2147483648.0",
  #|    "-2147483649.0",
  #|    "2147483647.0",
  #|    "2147483648.0",
  #|    "-9.223372036854776e+18",
  #|    "9.223372036854776e+18",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f64->str/lenient",
  #|  "result": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-2.5",
  #|    "0.1",
  #|    "1e+20",
  #|    "1e+300",
  #|    "123456789.125",
  #|    "NaN",
  #|    "inf",
  #|    "-inf",
  #|    "-2147483648.0",
  #|    "-2147483649.0",
  #|    "2147483647.0",
  #|    "2147483648.0",
  #|    "-9.223372036854776e+18",
  #|    "9.223372036854776e+18",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "str"
  #| },
  #| {
  #|  "error": "ComputeError",
  #|  "from": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-2.5",
  #|    "0.1",
  #|    "1e+20",
  #|    "1e+300",
  #|    "123456789.125",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    "-2147483648.0",
  #|    "-2147483649.0",
  #|    "2147483647.0",
  #|    "2147483648.0",
  #|    "-9.223372036854776e+18",
  #|    "9.223372036854776e+18",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f64->date/strict",
  #|  "polars_error": "InvalidOperationError: conversion from `f64` to `date` failed in column 'a' for 9 out of 18 values: [1.0000e20, 1.0000e300, … 9.2234e18]",
  #|  "strict": true,
  #|  "to": "date"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-2.5",
  #|    "0.1",
  #|    "1e+20",
  #|    "1e+300",
  #|    "123456789.125",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    "-2147483648.0",
  #|    "-2147483649.0",
  #|    "2147483647.0",
  #|    "2147483648.0",
  #|    "-9.223372036854776e+18",
  #|    "9.223372036854776e+18",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f64->date/lenient",
  #|  "result": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "0",
  #|    "1",
  #|    "-2",
  #|    "0",
  #|    null,
  #|    null,
  #|    "123456789",
  #|    null,
  #|    null,
  #|    null,
  #|    "-2147483648",
  #|    null,
  #|    "2147483647",
  #|    null,
  #|    null,
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "date"
  #| },
  #| {
  #|  "error": "ComputeError",
  #|  "from": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-2.5",
  #|    "0.1",
  #|    "1e+20",
  #|    "1e+300",
  #|    "123456789.125",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    "-2147483648.0",
  #|    "-2147483649.0",
  #|    "2147483647.0",
  #|    "2147483648.0",
  #|    "-9.223372036854776e+18",
  #|    "9.223372036854776e+18",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f64->datetime[μs]/strict",
  #|  "polars_error": "InvalidOperationError: conversion from `f64` to `datetime[μs]` failed in column 'a' for 6 out of 18 values: [1.0000e20, 1.0000e300, … 9.2234e18]",
  #|  "strict": true,
  #|  "to": "datetime[μs]"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-2.5",
  #|    "0.1",
  #|    "1e+20",
  #|    "1e+300",
  #|    "123456789.125",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    "-2147483648.0",
  #|    "-2147483649.0",
  #|    "2147483647.0",
  #|    "2147483648.0",
  #|    "-9.223372036854776e+18",
  #|    "9.223372036854776e+18",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f64->datetime[μs]/lenient",
  #|  "result": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "0",
  #|    "1",
  #|    "-2",
  #|    "0",
  #|    null,
  #|    null,
  #|    "123456789",
  #|    null,
  #|    null,
  #|    null,
  #|    "-2147483648",
  #|    "-2147483649",
  #|    "2147483647",
  #|    "2147483648",
  #|    "-9223372036854775808",
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "datetime[μs]"
  #| },
  #| {
  #|  "error": "ComputeError",
  #|  "from": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-2.5",
  #|    "0.1",
  #|    "1e+20",
  #|    "1e+300",
  #|    "123456789.125",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    "-2147483648.0",
  #|    "-2147483649.0",
  #|    "2147483647.0",
  #|    "2147483648.0",
  #|    "-9.223372036854776e+18",
  #|    "9.223372036854776e+18",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f64->null/strict",
  #|  "polars_error": "InvalidOperationError: conversion from `f64` to `null` failed in column 'a' for 17 out of 18 values: [0.0, -0.0, … inf]\n\nDid not show all failed cases as there were too many.",
  #|  "strict": true,
  #|  "to": "null"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-0.0",
  #|    "1.5",
  #|    "-2.5",
  #|    "0.1",
  #|    "1e+20",
  #|    "1e+300",
  #|    "123456789.125",
  #|    "nan",
  #|    "inf",
  #|    "-inf",
  #|    "-2147483648.0",
  #|    "-2147483649.0",
  #|    "2147483647.0",
  #|    "2147483648.0",
  #|    "-9.223372036854776e+18",
  #|    "9.223372036854776e+18",
  #|    null
  #|   ]
  #|  },
  #|  "id": "f64->null/lenient",
  #|  "result": {
  #|   "dtype": "null",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "null"
  #| },
  #| {
  #|  "error": "InvalidOperation",
  #|  "from": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "-7",
  #|    " 3",
  #|    "1.5",
  #|    "1e3",
  #|    "true",
  #|    "False",
  #|    "2024-02-29",
  #|    "1969-12-31",
  #|    "2024-01-01 12:34:56",
  #|    "2024-01-01T12:34:56.123456",
  #|    "abc",
  #|    "",
  #|    "9223372036854775808",
  #|    null
  #|   ]
  #|  },
  #|  "id": "str->bool/strict",
  #|  "polars_error": "InvalidOperationError: casting from Utf8View to Boolean not supported",
  #|  "strict": true,
  #|  "to": "bool"
  #| },
  #| {
  #|  "error": "InvalidOperation",
  #|  "from": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "-7",
  #|    " 3",
  #|    "1.5",
  #|    "1e3",
  #|    "true",
  #|    "False",
  #|    "2024-02-29",
  #|    "1969-12-31",
  #|    "2024-01-01 12:34:56",
  #|    "2024-01-01T12:34:56.123456",
  #|    "abc",
  #|    "",
  #|    "9223372036854775808",
  #|    null
  #|   ]
  #|  },
  #|  "id": "str->bool/lenient",
  #|  "polars_error": "InvalidOperationError: casting from Utf8View to Boolean not supported",
  #|  "strict": false,
  #|  "to": "bool"
  #| },
  #| {
  #|  "error": "ComputeError",
  #|  "from": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "-7",
  #|    " 3",
  #|    "1.5",
  #|    "1e3",
  #|    "true",
  #|    "False",
  #|    "2024-02-29",
  #|    "1969-12-31",
  #|    "2024-01-01 12:34:56",
  #|    "2024-01-01T12:34:56.123456",
  #|    "abc",
  #|    "",
  #|    "9223372036854775808",
  #|    null
  #|   ]
  #|  },
  #|  "id": "str->i32/strict",
  #|  "polars_error": "InvalidOperationError: conversion from `str` to `i32` failed in column 'a' for 12 out of 15 values: [\" 3\", \"1.5\", … \"abc\"]\n\nDid not show all failed cases as there were too many.",
  #|  "strict": true,
  #|  "to": "i32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "-7",
  #|    " 3",
  #|    "1.5",
  #|    "1e3",
  #|    "true",
  #|    "False",
  #|    "2024-02-29",
  #|    "1969-12-31",
  #|    "2024-01-01 12:34:56",
  #|    "2024-01-01T12:34:56.123456",
  #|    "abc",
  #|    "",
  #|    "9223372036854775808",
  #|    null
  #|   ]
  #|  },
  #|  "id": "str->i32/lenient",
  #|  "result": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "-7",
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "i32"
  #| },
  #| {
  #|  "error": "ComputeError",
  #|  "from": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "-7",
  #|    " 3",
  #|    "1.5",
  #|    "1e3",
  #|    "true",
  #|    "False",
  #|    "2024-02-29",
  #|    "1969-12-31",
  #|    "2024-01-01 12:34:56",
  #|    "2024-01-01T12:34:56.123456",
  #|    "abc",
  #|    "",
  #|    "9223372036854775808",
  #|    null
  #|   ]
  #|  },
  #|  "id": "str->i64/strict",
  #|  "polars_error": "InvalidOperationError: conversion from `str` to `i64` failed in column 'a' for 12 out of 15 values: [\" 3\", \"1.5\", … \"abc\"]\n\nDid not show all failed cases as there were too many.",
  #|  "strict": true,
  #|  "to": "i64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "-7",
  #|    " 3",
  #|    "1.5",
  #|    "1e3",
  #|    "true",
  #|    "False",
  #|    "2024-02-29",
  #|    "1969-12-31",
  #|    "2024-01-01 12:34:56",
  #|    "2024-01-01T12:34:56.123456",
  #|    "abc",
  #|    "",
  #|    "9223372036854775808",
  #|    null
  #|   ]
  #|  },
  #|  "id": "str->i64/lenient",
  #|  "result": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "-7",
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "i64"
  #| },
  #| {
  #|  "error": "ComputeError",
  #|  "from": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "-7",
  #|    " 3",
  #|    "1.5",
  #|    "1e3",
  #|    "true",
  #|    "False",
  #|    "2024-02-29",
  #|    "1969-12-31",
  #|    "2024-01-01 12:34:56",
  #|    "2024-01-01T12:34:56.123456",
  #|    "abc",
  #|    "",
  #|    "9223372036854775808",
  #|    null
  #|   ]
  #|  },
  #|  "id": "str->f32/strict",
  #|  "polars_error": "InvalidOperationError: conversion from `str` to `f32` failed in column 'a' for 9 out of 15 values: [\" 3\", \"true\", … \"\"]",
  #|  "strict": true,
  #|  "to": "f32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "-7",
  #|    " 3",
  #|    "1.5",
  #|    "1e3",
  #|    "true",
  #|    "False",
  #|    "2024-02-29",
  #|    "1969-12-31",
  #|    "2024-01-01 12:34:56",
  #|    "2024-01-01T12:34:56.123456",
  #|    "abc",
  #|    "",
  #|    "9223372036854775808",
  #|    null
  #|   ]
  #|  },
  #|  "id": "str->f32/lenient",
  #|  "result": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "1.0",
  #|    "-7.0",
  #|    null,
  #|    "1.5",
  #|    "1000.0",
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    "9.223372036854776e+18",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "f32"
  #| },
  #| {
  #|  "error": "ComputeError",
  #|  "from": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "-7",
  #|    " 3",
  #|    "1.5",
  #|    "1e3",
  #|    "true",
  #|    "False",
  #|    "2024-02-29",
  #|    "1969-12-31",
  #|    "2024-01-01 12:34:56",
  #|    "2024-01-01T12:34:56.123456",
  #|    "abc",
  #|    "",
  #|    "9223372036854775808",
  #|    null
  #|   ]
  #|  },
  #|  "id": "str->f64/strict",
  #|  "polars_error": "InvalidOperationError: conversion from `str` to `f64` failed in column 'a' for 9 out of 15 values: [\" 3\", \"true\", … \"\"]",
  #|  "strict": true,
  #|  "to": "f64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "-7",
  #|    " 3",
  #|    "1.5",
  #|    "1e3",
  #|    "true",
  #|    "False",
  #|    "2024-02-29",
  #|    "1969-12-31",
  #|    "2024-01-01 12:34:56",
  #|    "2024-01-01T12:34:56.123456",
  #|    "abc",
  #|    "",
  #|    "9223372036854775808",
  #|    null
  #|   ]
  #|  },
  #|  "id": "str->f64/lenient",
  #|  "result": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "1.0",
  #|    "-7.0",
  #|    null,
  #|    "1.5",
  #|    "1000.0",
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    "9.223372036854776e+18",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "f64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "-7",
  #|    " 3",
  #|    "1.5",
  #|    "1e3",
  #|    "true",
  #|    "False",
  #|    "2024-02-29",
  #|    "1969-12-31",
  #|    "2024-01-01 12:34:56",
  #|    "2024-01-01T12:34:56.123456",
  #|    "abc",
  #|    "",
  #|    "9223372036854775808",
  #|    null
  #|   ]
  #|  },
  #|  "id": "str->str/strict",
  #|  "result": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "-7",
  #|    " 3",
  #|    "1.5",
  #|    "1e3",
  #|    "true",
  #|    "False",
  #|    "2024-02-29",
  #|    "1969-12-31",
  #|    "2024-01-01 12:34:56",
  #|    "2024-01-01T12:34:56.123456",
  #|    "abc",
  #|    "",
  #|    "9223372036854775808",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "str"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "-7",
  #|    " 3",
  #|    "1.5",
  #|    "1e3",
  #|    "true",
  #|    "False",
  #|    "2024-02-29",
  #|    "1969-12-31",
  #|    "2024-01-01 12:34:56",
  #|    "2024-01-01T12:34:56.123456",
  #|    "abc",
  #|    "",
  #|    "9223372036854775808",
  #|    null
  #|   ]
  #|  },
  #|  "id": "str->str/lenient",
  #|  "result": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "-7",
  #|    " 3",
  #|    "1.5",
  #|    "1e3",
  #|    "true",
  #|    "False",
  #|    "2024-02-29",
  #|    "1969-12-31",
  #|    "2024-01-01 12:34:56",
  #|    "2024-01-01T12:34:56.123456",
  #|    "abc",
  #|    "",
  #|    "9223372036854775808",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "str"
  #| },
  #| {
  #|  "error": "InvalidOperation",
  #|  "from": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "-7",
  #|    " 3",
  #|    "1.5",
  #|    "1e3",
  #|    "true",
  #|    "False",
  #|    "2024-02-29",
  #|    "1969-12-31",
  #|    "2024-01-01 12:34:56",
  #|    "2024-01-01T12:34:56.123456",
  #|    "abc",
  #|    "",
  #|    "9223372036854775808",
  #|    null
  #|   ]
  #|  },
  #|  "id": "str->date/strict",
  #|  "polars_error": "InvalidOperationError: casting from string to date is not supported.\nIt was removed in Polars 2.0. Use `str.to_date()` instead.",
  #|  "strict": true,
  #|  "to": "date"
  #| },
  #| {
  #|  "error": "InvalidOperation",
  #|  "from": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "-7",
  #|    " 3",
  #|    "1.5",
  #|    "1e3",
  #|    "true",
  #|    "False",
  #|    "2024-02-29",
  #|    "1969-12-31",
  #|    "2024-01-01 12:34:56",
  #|    "2024-01-01T12:34:56.123456",
  #|    "abc",
  #|    "",
  #|    "9223372036854775808",
  #|    null
  #|   ]
  #|  },
  #|  "id": "str->date/lenient",
  #|  "polars_error": "InvalidOperationError: casting from string to date is not supported.\nIt was removed in Polars 2.0. Use `str.to_date()` instead.",
  #|  "strict": false,
  #|  "to": "date"
  #| },
  #| {
  #|  "error": "InvalidOperation",
  #|  "from": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "-7",
  #|    " 3",
  #|    "1.5",
  #|    "1e3",
  #|    "true",
  #|    "False",
  #|    "2024-02-29",
  #|    "1969-12-31",
  #|    "2024-01-01 12:34:56",
  #|    "2024-01-01T12:34:56.123456",
  #|    "abc",
  #|    "",
  #|    "9223372036854775808",
  #|    null
  #|   ]
  #|  },
  #|  "id": "str->datetime[μs]/strict",
  #|  "polars_error": "InvalidOperationError: casting from string to datetime is not supported.\nIt was removed in Polars 2.0. Use `str.to_datetime()` instead.",
  #|  "strict": true,
  #|  "to": "datetime[μs]"
  #| },
  #| {
  #|  "error": "InvalidOperation",
  #|  "from": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "-7",
  #|    " 3",
  #|    "1.5",
  #|    "1e3",
  #|    "true",
  #|    "False",
  #|    "2024-02-29",
  #|    "1969-12-31",
  #|    "2024-01-01 12:34:56",
  #|    "2024-01-01T12:34:56.123456",
  #|    "abc",
  #|    "",
  #|    "9223372036854775808",
  #|    null
  #|   ]
  #|  },
  #|  "id": "str->datetime[μs]/lenient",
  #|  "polars_error": "InvalidOperationError: casting from string to datetime is not supported.\nIt was removed in Polars 2.0. Use `str.to_datetime()` instead.",
  #|  "strict": false,
  #|  "to": "datetime[μs]"
  #| },
  #| {
  #|  "error": "ComputeError",
  #|  "from": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "-7",
  #|    " 3",
  #|    "1.5",
  #|    "1e3",
  #|    "true",
  #|    "False",
  #|    "2024-02-29",
  #|    "1969-12-31",
  #|    "2024-01-01 12:34:56",
  #|    "2024-01-01T12:34:56.123456",
  #|    "abc",
  #|    "",
  #|    "9223372036854775808",
  #|    null
  #|   ]
  #|  },
  #|  "id": "str->null/strict",
  #|  "polars_error": "InvalidOperationError: conversion from `str` to `null` failed in column 'a' for 14 out of 15 values: [\"1\", \"-7\", … \"2024-01-01 12:34:56\"]\n\nDid not show all failed cases as there were too many.",
  #|  "strict": true,
  #|  "to": "null"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "1",
  #|    "-7",
  #|    " 3",
  #|    "1.5",
  #|    "1e3",
  #|    "true",
  #|    "False",
  #|    "2024-02-29",
  #|    "1969-12-31",
  #|    "2024-01-01 12:34:56",
  #|    "2024-01-01T12:34:56.123456",
  #|    "abc",
  #|    "",
  #|    "9223372036854775808",
  #|    null
  #|   ]
  #|  },
  #|  "id": "str->null/lenient",
  #|  "result": {
  #|   "dtype": "null",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "null"
  #| },
  #| {
  #|  "error": "InvalidOperation",
  #|  "from": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "19782",
  #|    "-25567",
  #|    "2932896",
  #|    "106751991",
  #|    "106751992",
  #|    "-106751991",
  #|    "-106751992",
  #|    null
  #|   ]
  #|  },
  #|  "id": "date->bool/strict",
  #|  "polars_error": "InvalidOperationError: casting from Date to Boolean not supported",
  #|  "strict": true,
  #|  "to": "bool"
  #| },
  #| {
  #|  "error": "InvalidOperation",
  #|  "from": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "19782",
  #|    "-25567",
  #|    "2932896",
  #|    "106751991",
  #|    "106751992",
  #|    "-106751991",
  #|    "-106751992",
  #|    null
  #|   ]
  #|  },
  #|  "id": "date->bool/lenient",
  #|  "polars_error": "InvalidOperationError: casting from Date to Boolean not supported",
  #|  "strict": false,
  #|  "to": "bool"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "19782",
  #|    "-25567",
  #|    "2932896",
  #|    "106751991",
  #|    "106751992",
  #|    "-106751991",
  #|    "-106751992",
  #|    null
  #|   ]
  #|  },
  #|  "id": "date->i32/strict",
  #|  "result": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "19782",
  #|    "-25567",
  #|    "2932896",
  #|    "106751991",
  #|    "106751992",
  #|    "-106751991",
  #|    "-106751992",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "i32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "19782",
  #|    "-25567",
  #|    "2932896",
  #|    "106751991",
  #|    "106751992",
  #|    "-106751991",
  #|    "-106751992",
  #|    null
  #|   ]
  #|  },
  #|  "id": "date->i32/lenient",
  #|  "result": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "19782",
  #|    "-25567",
  #|    "2932896",
  #|    "106751991",
  #|    "106751992",
  #|    "-106751991",
  #|    "-106751992",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "i32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "19782",
  #|    "-25567",
  #|    "2932896",
  #|    "106751991",
  #|    "106751992",
  #|    "-106751991",
  #|    "-106751992",
  #|    null
  #|   ]
  #|  },
  #|  "id": "date->i64/strict",
  #|  "result": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "19782",
  #|    "-25567",
  #|    "2932896",
  #|    "106751991",
  #|    "106751992",
  #|    "-106751991",
  #|    "-106751992",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "i64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "19782",
  #|    "-25567",
  #|    "2932896",
  #|    "106751991",
  #|    "106751992",
  #|    "-106751991",
  #|    "-106751992",
  #|    null
  #|   ]
  #|  },
  #|  "id": "date->i64/lenient",
  #|  "result": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "19782",
  #|    "-25567",
  #|    "2932896",
  #|    "106751991",
  #|    "106751992",
  #|    "-106751991",
  #|    "-106751992",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "i64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "19782",
  #|    "-25567",
  #|    "2932896",
  #|    "106751991",
  #|    "106751992",
  #|    "-106751991",
  #|    "-106751992",
  #|    null
  #|   ]
  #|  },
  #|  "id": "date->f32/strict",
  #|  "result": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-1.0",
  #|    "19782.0",
  #|    "-25567.0",
  #|    "2932896.0",
  #|    "106751992.0",
  #|    "106751992.0",
  #|    "-106751992.0",
  #|    "-106751992.0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "f32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "19782",
  #|    "-25567",
  #|    "2932896",
  #|    "106751991",
  #|    "106751992",
  #|    "-106751991",
  #|    "-106751992",
  #|    null
  #|   ]
  #|  },
  #|  "id": "date->f32/lenient",
  #|  "result": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-1.0",
  #|    "19782.0",
  #|    "-25567.0",
  #|    "2932896.0",
  #|    "106751992.0",
  #|    "106751992.0",
  #|    "-106751992.0",
  #|    "-106751992.0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "f32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "19782",
  #|    "-25567",
  #|    "2932896",
  #|    "106751991",
  #|    "106751992",
  #|    "-106751991",
  #|    "-106751992",
  #|    null
  #|   ]
  #|  },
  #|  "id": "date->f64/strict",
  #|  "result": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-1.0",
  #|    "19782.0",
  #|    "-25567.0",
  #|    "2932896.0",
  #|    "106751991.0",
  #|    "106751992.0",
  #|    "-106751991.0",
  #|    "-106751992.0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "f64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "19782",
  #|    "-25567",
  #|    "2932896",
  #|    "106751991",
  #|    "106751992",
  #|    "-106751991",
  #|    "-106751992",
  #|    null
  #|   ]
  #|  },
  #|  "id": "date->f64/lenient",
  #|  "result": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-1.0",
  #|    "19782.0",
  #|    "-25567.0",
  #|    "2932896.0",
  #|    "106751991.0",
  #|    "106751992.0",
  #|    "-106751991.0",
  #|    "-106751992.0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "f64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "19782",
  #|    "-25567",
  #|    "2932896",
  #|    null
  #|   ]
  #|  },
  #|  "id": "date->str/strict",
  #|  "omitted_values": [
  #|   "106751991",
  #|   "106751992",
  #|   "-106751991",
  #|   "-106751992"
  #|  ],
  #|  "result": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "1970-01-01",
  #|    "1969-12-31",
  #|    "2024-02-29",
  #|    "1900-01-01",
  #|    "9999-12-31",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "str"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "19782",
  #|    "-25567",
  #|    "2932896",
  #|    null
  #|   ]
  #|  },
  #|  "id": "date->str/lenient",
  #|  "omitted_values": [
  #|   "106751991",
  #|   "106751992",
  #|   "-106751991",
  #|   "-106751992"
  #|  ],
  #|  "result": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "1970-01-01",
  #|    "1969-12-31",
  #|    "2024-02-29",
  #|    "1900-01-01",
  #|    "9999-12-31",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "str"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "19782",
  #|    "-25567",
  #|    "2932896",
  #|    "106751991",
  #|    "106751992",
  #|    "-106751991",
  #|    "-106751992",
  #|    null
  #|   ]
  #|  },
  #|  "id": "date->date/strict",
  #|  "result": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "19782",
  #|    "-25567",
  #|    "2932896",
  #|    "106751991",
  #|    "106751992",
  #|    "-106751991",
  #|    "-106751992",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "date"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "19782",
  #|    "-25567",
  #|    "2932896",
  #|    "106751991",
  #|    "106751992",
  #|    "-106751991",
  #|    "-106751992",
  #|    null
  #|   ]
  #|  },
  #|  "id": "date->date/lenient",
  #|  "result": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "19782",
  #|    "-25567",
  #|    "2932896",
  #|    "106751991",
  #|    "106751992",
  #|    "-106751991",
  #|    "-106751992",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "date"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "19782",
  #|    "-25567",
  #|    "2932896",
  #|    "106751991",
  #|    "-106751991",
  #|    null
  #|   ]
  #|  },
  #|  "id": "date->datetime[μs]/strict",
  #|  "omitted_values": [
  #|   "106751992",
  #|   "-106751992"
  #|  ],
  #|  "result": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-86400000000",
  #|    "1709164800000000",
  #|    "-2208988800000000",
  #|    "253402214400000000",
  #|    "9223372022400000000",
  #|    "-9223372022400000000",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "datetime[μs]"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "19782",
  #|    "-25567",
  #|    "2932896",
  #|    "106751991",
  #|    "106751992",
  #|    "-106751991",
  #|    "-106751992",
  #|    null
  #|   ]
  #|  },
  #|  "id": "date->datetime[μs]/lenient",
  #|  "result": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-86400000000",
  #|    "1709164800000000",
  #|    "-2208988800000000",
  #|    "253402214400000000",
  #|    "9223372022400000000",
  #|    null,
  #|    "-9223372022400000000",
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "datetime[μs]"
  #| },
  #| {
  #|  "error": "InvalidOperation",
  #|  "from": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "19782",
  #|    "-25567",
  #|    "2932896",
  #|    "106751991",
  #|    "106751992",
  #|    "-106751991",
  #|    "-106751992",
  #|    null
  #|   ]
  #|  },
  #|  "id": "date->null/strict",
  #|  "polars_error": "InvalidOperationError: casting from Date to Null not supported",
  #|  "strict": true,
  #|  "to": "null"
  #| },
  #| {
  #|  "error": "InvalidOperation",
  #|  "from": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "19782",
  #|    "-25567",
  #|    "2932896",
  #|    "106751991",
  #|    "106751992",
  #|    "-106751991",
  #|    "-106751992",
  #|    null
  #|   ]
  #|  },
  #|  "id": "date->null/lenient",
  #|  "polars_error": "InvalidOperationError: casting from Date to Null not supported",
  #|  "strict": false,
  #|  "to": "null"
  #| },
  #| {
  #|  "error": "InvalidOperation",
  #|  "from": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "1709210096123456",
  #|    "86399999999",
  #|    "-86400000001",
  #|    null
  #|   ]
  #|  },
  #|  "id": "datetime[μs]->bool/strict",
  #|  "polars_error": "InvalidOperationError: casting from Datetime('μs') to Boolean not supported",
  #|  "strict": true,
  #|  "to": "bool"
  #| },
  #| {
  #|  "error": "InvalidOperation",
  #|  "from": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "1709210096123456",
  #|    "86399999999",
  #|    "-86400000001",
  #|    null
  #|   ]
  #|  },
  #|  "id": "datetime[μs]->bool/lenient",
  #|  "polars_error": "InvalidOperationError: casting from Datetime('μs') to Boolean not supported",
  #|  "strict": false,
  #|  "to": "bool"
  #| },
  #| {
  #|  "error": "ComputeError",
  #|  "from": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "1709210096123456",
  #|    "86399999999",
  #|    "-86400000001",
  #|    null
  #|   ]
  #|  },
  #|  "id": "datetime[μs]->i32/strict",
  #|  "polars_error": "InvalidOperationError: conversion from `datetime[μs]` to `i32` failed in column 'a' for 3 out of 6 values: [2024-02-29 12:34:56.123456, 1970-01-01 23:59:59.999999, 1969-12-30 23:59:59.999999]",
  #|  "strict": true,
  #|  "to": "i32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "1709210096123456",
  #|    "86399999999",
  #|    "-86400000001",
  #|    null
  #|   ]
  #|  },
  #|  "id": "datetime[μs]->i32/lenient",
  #|  "result": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    null,
  #|    null,
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "i32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "1709210096123456",
  #|    "86399999999",
  #|    "-86400000001",
  #|    null
  #|   ]
  #|  },
  #|  "id": "datetime[μs]->i64/strict",
  #|  "result": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "1709210096123456",
  #|    "86399999999",
  #|    "-86400000001",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "i64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "1709210096123456",
  #|    "86399999999",
  #|    "-86400000001",
  #|    null
  #|   ]
  #|  },
  #|  "id": "datetime[μs]->i64/lenient",
  #|  "result": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "1709210096123456",
  #|    "86399999999",
  #|    "-86400000001",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "i64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "1709210096123456",
  #|    "86399999999",
  #|    "-86400000001",
  #|    null
  #|   ]
  #|  },
  #|  "id": "datetime[μs]->f32/strict",
  #|  "result": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-1.0",
  #|    "1709210152730624.0",
  #|    "86400000000.0",
  #|    "-86400000000.0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "f32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "1709210096123456",
  #|    "86399999999",
  #|    "-86400000001",
  #|    null
  #|   ]
  #|  },
  #|  "id": "datetime[μs]->f32/lenient",
  #|  "result": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-1.0",
  #|    "1709210152730624.0",
  #|    "86400000000.0",
  #|    "-86400000000.0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "f32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "1709210096123456",
  #|    "86399999999",
  #|    "-86400000001",
  #|    null
  #|   ]
  #|  },
  #|  "id": "datetime[μs]->f64/strict",
  #|  "result": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-1.0",
  #|    "1709210096123456.0",
  #|    "86399999999.0",
  #|    "-86400000001.0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "f64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "1709210096123456",
  #|    "86399999999",
  #|    "-86400000001",
  #|    null
  #|   ]
  #|  },
  #|  "id": "datetime[μs]->f64/lenient",
  #|  "result": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    "0.0",
  #|    "-1.0",
  #|    "1709210096123456.0",
  #|    "86399999999.0",
  #|    "-86400000001.0",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "f64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "1709210096123456",
  #|    "86399999999",
  #|    "-86400000001",
  #|    null
  #|   ]
  #|  },
  #|  "id": "datetime[μs]->str/strict",
  #|  "result": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "1970-01-01 00:00:00.000000",
  #|    "1969-12-31 23:59:59.999999",
  #|    "2024-02-29 12:34:56.123456",
  #|    "1970-01-01 23:59:59.999999",
  #|    "1969-12-30 23:59:59.999999",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "str"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "1709210096123456",
  #|    "86399999999",
  #|    "-86400000001",
  #|    null
  #|   ]
  #|  },
  #|  "id": "datetime[μs]->str/lenient",
  #|  "result": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    "1970-01-01 00:00:00.000000",
  #|    "1969-12-31 23:59:59.999999",
  #|    "2024-02-29 12:34:56.123456",
  #|    "1970-01-01 23:59:59.999999",
  #|    "1969-12-30 23:59:59.999999",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "str"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "1709210096123456",
  #|    "86399999999",
  #|    "-86400000001",
  #|    null
  #|   ]
  #|  },
  #|  "id": "datetime[μs]->date/strict",
  #|  "result": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "19782",
  #|    "0",
  #|    "-2",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "date"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "1709210096123456",
  #|    "86399999999",
  #|    "-86400000001",
  #|    null
  #|   ]
  #|  },
  #|  "id": "datetime[μs]->date/lenient",
  #|  "result": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "19782",
  #|    "0",
  #|    "-2",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "date"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "1709210096123456",
  #|    "86399999999",
  #|    "-86400000001",
  #|    null
  #|   ]
  #|  },
  #|  "id": "datetime[μs]->datetime[μs]/strict",
  #|  "result": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "1709210096123456",
  #|    "86399999999",
  #|    "-86400000001",
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "datetime[μs]"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "1709210096123456",
  #|    "86399999999",
  #|    "-86400000001",
  #|    null
  #|   ]
  #|  },
  #|  "id": "datetime[μs]->datetime[μs]/lenient",
  #|  "result": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "1709210096123456",
  #|    "86399999999",
  #|    "-86400000001",
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "datetime[μs]"
  #| },
  #| {
  #|  "error": "InvalidOperation",
  #|  "from": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "1709210096123456",
  #|    "86399999999",
  #|    "-86400000001",
  #|    null
  #|   ]
  #|  },
  #|  "id": "datetime[μs]->null/strict",
  #|  "polars_error": "InvalidOperationError: casting from Datetime('μs') to Null not supported",
  #|  "strict": true,
  #|  "to": "null"
  #| },
  #| {
  #|  "error": "InvalidOperation",
  #|  "from": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    "0",
  #|    "-1",
  #|    "1709210096123456",
  #|    "86399999999",
  #|    "-86400000001",
  #|    null
  #|   ]
  #|  },
  #|  "id": "datetime[μs]->null/lenient",
  #|  "polars_error": "InvalidOperationError: casting from Datetime('μs') to Null not supported",
  #|  "strict": false,
  #|  "to": "null"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "null",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "id": "null->bool/strict",
  #|  "result": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "bool"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "null",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "id": "null->bool/lenient",
  #|  "result": {
  #|   "dtype": "bool",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "bool"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "null",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "id": "null->i32/strict",
  #|  "result": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "i32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "null",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "id": "null->i32/lenient",
  #|  "result": {
  #|   "dtype": "i32",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "i32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "null",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "id": "null->i64/strict",
  #|  "result": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "i64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "null",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "id": "null->i64/lenient",
  #|  "result": {
  #|   "dtype": "i64",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "i64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "null",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "id": "null->f32/strict",
  #|  "result": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "f32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "null",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "id": "null->f32/lenient",
  #|  "result": {
  #|   "dtype": "f32",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "f32"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "null",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "id": "null->f64/strict",
  #|  "result": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "f64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "null",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "id": "null->f64/lenient",
  #|  "result": {
  #|   "dtype": "f64",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "f64"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "null",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "id": "null->str/strict",
  #|  "result": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "str"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "null",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "id": "null->str/lenient",
  #|  "result": {
  #|   "dtype": "str",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "str"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "null",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "id": "null->date/strict",
  #|  "result": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "date"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "null",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "id": "null->date/lenient",
  #|  "result": {
  #|   "dtype": "date",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "date"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "null",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "id": "null->datetime[μs]/strict",
  #|  "result": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "datetime[μs]"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "null",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "id": "null->datetime[μs]/lenient",
  #|  "result": {
  #|   "dtype": "datetime[μs]",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "datetime[μs]"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "null",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "id": "null->null/strict",
  #|  "result": {
  #|   "dtype": "null",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": true,
  #|  "to": "null"
  #| },
  #| {
  #|  "from": {
  #|   "dtype": "null",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "id": "null->null/lenient",
  #|  "result": {
  #|   "dtype": "null",
  #|   "name": "a",
  #|   "values": [
  #|    null,
  #|    null
  #|   ]
  #|  },
  #|  "strict": false,
  #|  "to": "null"
  #| }
  #|]
