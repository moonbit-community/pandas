# 🐱NyaCSV 

> *Purr-fectly parse your CSV files with delightful simplicity!*

[English](https://github.com/moonbit-community/NyaCSV/blob/main/README.md) | [简体中文](https://github.com/moonbit-community/NyaCSV/blob/main/README_zh_CN.md)

[![Build Status](https://img.shields.io/github/actions/workflow/status/moonbit-community/NyaCSV/ci.yml)](https://github.com/moonbit-community/NyaCSV/actions)
[![License](https://img.shields.io/github/license/moonbit-community/NyaCSV)](LICENSE)
[![codecov](https://codecov.io/gh/moonbit-community/NyaCSV/branch/main/graph/badge.svg)](https://codecov.io/gh/moonbit-community/NyaCSV)

NyaCSV is a playful yet powerful CSV parsing and manipulation library for MoonBit that handles your data with cat-like grace and precision. Say goodbye to data hairballs and hello to elegantly structured information!

## ✨ Features

- **Multi-source Input** - Parse CSV from strings, binary data, or buffers... any data format a curious cat might find!
- **Custom Delimiters** - Not just commas! Use any character to separate your fields (because cats don't follow rules)
- **Smart Quote Handling** - Expertly handles quoted fields with special characters, like a cat delicately carrying its favorite toy
- **Header Management** - Auto-detect or generate column headers with feline intelligence
- **Whitespace Grooming** - Option to trim leading and trailing spaces, keeping your data as neat as a well-groomed kitty
- **Pretty Printed Output** - Display your data in beautiful table format that would make any cat proud to show off
- **Flexible Configuration** - Customize parsing behavior to match your exact needs, as demanding as the pickiest cat

## 🚀 Quick Start

```moonbit
fn main() {
  // Parse a simple CSV string
  let data = "Name,Age,Favorite Toy\nMittens,3,Ball of yarn\nWhiskers,5,Laser pointer"
  let csv = CSV::parse_string(data)
  
  // Display as a pretty table
  println!("{}", csv)
  
  // Access data directly
  println!("The first cat's name is: {}", csv.rows[0][0])
}
```

## 📦 Installation

Add NyaCSV to your MoonBit project:

```bash
moon add xunyoyo/NyaCSV
```

## 🧶 Usage Examples

### Parsing CSV with Custom Options

```moonbit
let options : CSVOptions = {
  delimiter: ';',
  allow_newlines_in_quotes: true,
  quote_char: '"',
  skip_empty_lines: true,
  trim_spaces: true
}

let cat_data = "Name;Description;Adopted\nSimba;\"Playful orange tabby\nLoves treats\";Yes"
let csv = CSV::parse_string(cat_data, options~)
```

### Creating CSV from Scratch

```moonbit
// Start with an empty CSV
let csv = CSV::new()

// Add headers and data programmatically
// ...

// Convert back to string
let csv_string = csv.to_string()
```

### Working with 2D Arrays

```moonbit
let cat_shelter_data = [
  ["Name", "Age", "Color", "Adopted"],
  ["Luna", "2", "Black", "Yes"],
  ["Oliver", "1", "Tabby", "No"],
  ["Bella", "4", "Calico", "Yes"]
]

let csv = CSV::from_array(cat_shelter_data)
println!("{}", csv)
```

## 🔍 API Reference

### Core Structures

#### CSV

```moonbit
struct CSV {
  headers : Array[String]
  rows : Array[Array[String]]
}
```

#### `CSVOptions`

```moonbit
struct CSVOptions {
  delimiter : Char              // Default: ','
  allow_newlines_in_quotes : Bool  // Default: true
  quote_char : Char             // Default: '"'
  skip_empty_lines : Bool       // Default: true
  trim_spaces : Bool            // Default: false
}
```

### Parsing Methods

- **`CSV::parse_string(data: String, options: CSVOptions) -> CSV`** - Parse CSV from string
- **`CSV::parse_buffer(data: Buffer, options: CSVOptions) -> CSV`** - Parse CSV from buffer
- **`CSV::parse_bytes(data: Bytes, options: CSVOptions) -> CSV`** - Parse CSV from bytes

### Creation Methods

- **`CSV::new() -> CSV`** - Create empty CSV
- **`CSV::from_array(data: Array[Array[String]], has_header: Bool = true, generate_headers: Bool = true) -> CSV`** - Create CSV from 2D array

### Display Methods

- **`to_string() -> String`** - Convert CSV back to string format
- **`output(logger) -> Unit`** - Display as a pretty formatted table

## 🎭 Advanced Examples

### Creating Pretty Tables

```moonbit
let cat_breeds = "Breed,Origin,Size,Temperament\nSiamese,Thailand,Medium,\"Vocal, Active\"\nMaine Coon,USA,Large,\"Gentle, Playful\"\nRagdoll,USA,Large,\"Calm, Affectionate\""

let csv = CSV::parse_string(cat_breeds)

// Print as a gorgeous table
println!("{}", csv)

// Output:
// +------------+---------+--------+--------------------+
// | Breed      | Origin  | Size   | Temperament        |
// +------------+---------+--------+--------------------+
// | Siamese    | Thailand| Medium | Vocal, Active      |
// | Maine Coon | USA     | Large  | Gentle, Playful    |
// | Ragdoll    | USA     | Large  | Calm, Affectionate |
// +------------+---------+--------+--------------------+
```

### Handling Multiline Fields

```moonbit
let cat_profiles = "Name,Bio\nLucy,\"Lucy is a curious cat.\nShe loves exploring.\"\nMax,\"Max is lazy.\nHe sleeps all day.\""

let csv = CSV::parse_string(cat_profiles)
println!("{}", csv)
```

## 🐾 Contribution

Contributions are welcome! Feel free to submit issues and pull requests to help make NyaCSV even more paw-some.

## 📜 License

Apache-2.0

---

*Made with <3 by cat lovers, for data lovers*