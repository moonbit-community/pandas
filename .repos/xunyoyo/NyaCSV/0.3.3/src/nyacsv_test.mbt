///|
test "CSV::output/empty_csv" {
  let csv = CSV::new()
  let logger = @buffer.new()
  csv.output(logger)
  inspect!(logger.contents().to_unchecked_string(), content="<Empty CSV>")
}

///|
test "CSV::to_string/empty" {
  let csv = CSV::new()
  inspect!(csv.to_string(), content="\n")
}

///|
test "CSV::from_array/empty_data" {
  let data : Array[Array[String]] = []
  let csv = CSV::from_array(data)
  inspect!(csv.header(), content="[]")
  inspect!(csv.data(), content="[]")
}

///|
test "CSV::from_array/header_present" {
  let data : Array[Array[String]] = [
    ["Name", "Age", "City"],
    ["Alice", "30", "Wonderland"],
  ]
  let csv = CSV::from_array(data)
  inspect!(csv.header(), content="[\"Name\", \"Age\", \"City\"]")
  inspect!(csv.data(), content="[[\"Alice\", \"30\", \"Wonderland\"]]")
}

///|
test "CSV::from_array/generate_headers" {
  let data : Array[Array[String]] = [
    ["Alice", "30", "Wonderland"],
    ["Bob", "25", "Builderland"],
  ]
  let csv = CSV::from_array(data, has_header=false, generate_headers=true)
  inspect!(csv.header(), content="[\"column1\", \"column2\", \"column3\"]")
  inspect!(
    csv.data(),
    content="[[\"Alice\", \"30\", \"Wonderland\"], [\"Bob\", \"25\", \"Builderland\"]]",
  )
}

///|
test "CSV::from_array/first_row_empty_with_header" {
  // 测试把空行当作表头的情况
  let data : Array[Array[String]] = [[], []]
  let csv = CSV::from_array(data, has_header=false)
  // 表头应该为空
  inspect!(csv.header(), content="[]")
  // 数据行应该只包含第二行
  inspect!(csv.data(), content="[[], []]")
}

///|
test "CSV::from_array/empty_data_with_generate_headers" {
  // 测试完全空的数组，但设置 generate_headers=true
  let data : Array[Array[String]] = []
  let csv = CSV::from_array(data, has_header=false, generate_headers=true)

  // 由于数据完全为空，column_count=0，所以应该生成空的头
  inspect!(csv.header(), content="[]")
  inspect!(csv.data(), content="[]")
}

///|
test "CSV::from_array/first_row_empty" {
  // 测试第一行为空数组的情况
  let data : Array[Array[String]] = [
    [], // 第一行为空
    ["Some", "Data", "Here"],
  ]
  let csv = CSV::from_array(data, has_header=false, generate_headers=true)

  // 由于第一行为空，所以column_count=0，不应该生成任何头
  inspect!(csv.header(), content="[]")
  // 但行数据应该保留
  inspect!(csv.data(), content="[[], [\"Some\", \"Data\", \"Here\"]]")
}

///|
test "CSV::from_array/first_row_empty_with_header" {
  // 测试把空行当作表头的情况
  let data : Array[Array[String]] = [
    [], // 空表头行
    ["Some", "Data", "Here"],
  ]
  let csv = CSV::from_array(data, has_header=false, generate_headers=false)

  // 表头应该为空
  inspect!(csv.header(), content="[]")
  // 数据行应该只包含第二行
  inspect!(csv.data(), content="[[], [\"Some\", \"Data\", \"Here\"]]")
}

///|
test "CSV::new/basic" {
  let csv = CSV::new()
  inspect!(csv.header(), content="[]")
  inspect!(csv.data(), content="[]")
}

///|
test "CSV::parse_string/basic_with_quoted_field" {
  let data = "first,last,address,city,zip\nJohn,Doe,120 any st.,\"Anytown, WW\",08123"
  let csv = CSV::parse_string(data)
  inspect!(
    csv.header(),
    content="[\"first\", \"last\", \"address\", \"city\", \"zip\"]",
  )
  inspect!(
    csv.data(),
    content="[[\"John\", \"Doe\", \"120 any st.\", \"Anytown, WW\", \"08123\"]]",
  )

  // 验证引号字段正确解析
  assert_eq!(csv.data()[0][3], "Anytown, WW")
}

///|
test "CSV::parse_string/crlf_with_empty_fields" {
  let data = "a,b,c\r\n1,\"\",\"\"\r\n2,3,4"
  let csv = CSV::parse_string(data)
  inspect!(csv.header(), content="[\"a\", \"b\", \"c\"]")
  inspect!(csv.data(), content="[[\"1\", \"\", \"\"], [\"2\", \"3\", \"4\"]]")

  // 验证空引号字段正确解析为空字符串
  assert_eq!(csv.data()[0][1], "")
  assert_eq!(csv.data()[0][2], "")
}

///|
test "CSV::parse_string/quoted_with_internal_quotes" {
  let data = "a,b\n1,\"ha \"\"ha\"\" ha\"\n3,4\n"
  let csv = CSV::parse_string(data)
  inspect!(csv.header(), content="[\"a\", \"b\"]")
  inspect!(
    csv.data(),
    content="[[\"1\", \"ha \\\"ha\\\" ha\"], [\"3\", \"4\"]]",
  )

  // 验证内部引号正确处理
  assert_eq!(csv.data()[0][1], "ha \"ha\" ha")
}

///|
test "CSV::parse_string/quoted_with_internal_quotes" {
  let data = "a,b\n1,\"ha \"\"ha\"\" ha\"\n3,4\n"
  let csv = CSV::parse_string(data)
  inspect!(csv.header(), content="[\"a\", \"b\"]")
  inspect!(
    csv.data(),
    content="[[\"1\", \"ha \\\"ha\\\" ha\"], [\"3\", \"4\"]]",
  )

  // 验证内部引号正确处理
  assert_eq!(csv.data()[0][1], "ha \"ha\" ha")
}

///|
test "CSV::parse_string/json_in_field" {
  let data = "key,val\n1,\"{\"\"type\"\": \"\"Point\"\", \"\"coordinates\"\": [102.0, 0.5]}\"\n"
  let csv = CSV::parse_string(data)
  inspect!(csv.header(), content="[\"key\", \"val\"]")
  // 验证JSON字符串被正确解析
  assert_eq!(
    csv.data()[0][1],
    "{\"type\": \"Point\", \"coordinates\": [102.0, 0.5]}",
  )
}

///|
test "CSV::parse_string/special_characters" {
  let data = "Contact Phone Number,Location Coordinates,Cities,Counties\n2095257564,37�36'37.8\"N 121�2'17.9\"W,Modesto,Stanislaus"
  let csv = CSV::parse_string(data)
  inspect!(
    csv.header(),
    content="[\"Contact Phone Number\", \"Location Coordinates\", \"Cities\", \"Counties\"]",
  )
  // 验证特殊字符被正确处理
  assert_eq!(csv.data()[0][1], "37�36'37.8\"N 121�2'17.9\"W")
}

///|
test "CSV::parse_string/multiline_fields_crlf" {
  let data = "a,b,c\r\n1,2,3\r\n\"Once upon \r\na time\",5,6\r\n7,8,9\r\n"
  let csv = CSV::parse_string(data)
  inspect!(csv.header(), content="[\"a\", \"b\", \"c\"]")
  // 验证多行字段正确处理
  assert_eq!(csv.data()[1][0], "Once upon \r\na time")
}

///|
test "CSV::parse_string/multiline_fields_lf" {
  let data = "a,b,c\n1,2,3\n\"Once upon \na time\",5,6\n7,8,9\n"
  let csv = CSV::parse_string(data)
  inspect!(csv.header(), content="[\"a\", \"b\", \"c\"]")

  // 验证LF换行符的多行字段正确处理
  assert_eq!(csv.data()[1][0], "Once upon \na time")
}

///|
test "CSV::parse_string/simple_crlf" {
  let data = "a,b,c\r\n1,2,3\r\n"
  let csv = CSV::parse_string(data)
  inspect!(csv.header(), content="[\"a\", \"b\", \"c\"]")
  inspect!(csv.data(), content="[[\"1\", \"2\", \"3\"]]")
}

///|
test "CSV::parse_string/unicode_characters" {
  let data = "a,b,c\n1,2,3\n4,5,ʤ"
  let csv = CSV::parse_string(data)
  inspect!(csv.header(), content="[\"a\", \"b\", \"c\"]")
  inspect!(
    csv.data(),
    content="[[\"1\", \"2\", \"3\"], [\"4\", \"5\", \"ʤ\"]]",
  )

  // 验证Unicode字符正确处理
  assert_eq!(csv.data()[1][2], "ʤ")
}

///|
test "CSV::parse_string/custom_delimiter" {
  let data = "first;last;address\nJohn;Doe;\"120 any st., Anytown\""
  let csv = CSV::parse_string(data, options=CSVOptions::{
    delimiter: ';',
    allow_newlines_in_quotes: true,
    quote_char: '"',
    skip_empty_lines: true,
    trim_spaces: false,
  })
  inspect!(csv.header(), content="[\"first\", \"last\", \"address\"]")
  inspect!(
    csv.data(),
    content="[[\"John\", \"Doe\", \"120 any st., Anytown\"]]",
  )

  // 验证自定义分隔符正确工作
  assert_eq!(csv.data()[0][2], "120 any st., Anytown")
}

///| Test for empty bytes input.
test "@nyacsv.CSV::parse_bytes/empty_bytes" {
  let data = Bytes::new(0) // Create an empty byte sequence.
  let csv = @NyaCSV.CSV::parse_bytes(data) // Call the `parse_bytes` function with empty data.
  // Check if the parsed CSV has no headers and no data rows.
  inspect!(csv.header(), content="[]")
  inspect!(csv.data(), content="[]")
}

///| Test for a single line of data with no header.
test "@nyacsv.CSV::parse_bytes/single_line_no_header" {
  // Create a byte sequence representing a single line of data values separated by commas.
  let data = Bytes::of_string("value1,value2,value3")
  // Call the `parse_bytes` function with no header present in the data.
  let csv = @NyaCSV.CSV::parse_bytes(data, options={
    delimiter: ',',
    allow_newlines_in_quotes: true,
    quote_char: '"',
    skip_empty_lines: true,
    trim_spaces: true,
  })

  // Check if the parsed CSV has expected data values with an implicit header.
  inspect!(csv.header(), content="[\"value1\", \"value2\", \"value3\"]")
}
