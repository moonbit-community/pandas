///| Compute absolute values.
///
/// Example
/// ```
/// let series = Series::new("test", SeriesInput::Int32([-1, 2, -3]))
/// inspect!(series.abs!().data, content="Int([1, 2, 3])")
/// let series = Series::new("test", SeriesInput::Float32([-1.5, 2.0, -3.0]))
/// inspect!(series.abs!().data, content="Float([1.5, 2, 3])")
/// ```
pub fn Series::abs(self : Series) -> Series!InvalidType {
  match self.data {
    SeriesData::Int(data) =>
      Series::new(self.name, SeriesInput::Int32(data.map(fn(x) { x.abs() })))
    SeriesData::Float(data) =>
      Series::new(self.name, SeriesInput::Float32(data.map(fn(x) { x.abs() })))
    _ => raise InvalidType("unsupported type")
  }
}

///| Compute the element-wise value for the cosine.
///
/// Example
/// ```
/// let series = Series::new("test", SeriesInput::Float32([1.0, 1.5, 2.0]))
/// let cos = series.cos()
/// ```
pub fn Series::cos(self : Series) -> Series!InvalidType {
  match self.data {
    SeriesData::Int(data) =>
      Series::new(
        self.name,
        SeriesInput::Float32(
          data.map(fn(x) { @math.cos(x.to_double()).to_float() }),
        ),
      )
    SeriesData::Float(data) =>
      Series::new(
        self.name,
        SeriesInput::Float32(
          data.map(fn(x) { @math.cos(x.to_double()).to_float() }),
        ),
      )
    _ => raise InvalidType("unsupported type")
  }
}

///| Compute the element-wise value for the sine.
///
/// Example
/// ```
/// let series = Series::new("test", SeriesInput::Float32([1.0, 1.5, 2.0]))
/// let sin = series.sin()
/// ```
pub fn Series::sin(self : Series) -> Series!InvalidType {
  match self.data {
    SeriesData::Int(data) =>
      Series::new(
        self.name,
        SeriesInput::Float32(
          data.map(fn(x) { @math.sin(x.to_double()).to_float() }),
        ),
      )
    SeriesData::Float(data) =>
      Series::new(
        self.name,
        SeriesInput::Float32(
          data.map(fn(x) { @math.sin(x.to_double()).to_float() }),
        ),
      )
    _ => raise InvalidType("unsupported type")
  }
}

///| Compute the element-wise value for the tangent.
///
/// Example
/// ```
/// let series = Series::new("test", SeriesInput::Float32([1.0, 1.5, 2.0]))
/// let tan = series.tan()
/// ```
pub fn Series::tan(self : Series) -> Series!InvalidType {
  match self.data {
    SeriesData::Int(data) =>
      Series::new(
        self.name,
        SeriesInput::Float32(
          data.map(fn(x) { @math.tan(x.to_double()).to_float() }),
        ),
      )
    SeriesData::Float(data) =>
      Series::new(
        self.name,
        SeriesInput::Float32(
          data.map(fn(x) { @math.tan(x.to_double()).to_float() }),
        ),
      )
    _ => raise InvalidType("unsupported type")
  }
}

///| Compute the element-wise value for the acos.
///
/// Example
/// ```
/// let series = Series::new("test", SeriesInput::Float32([1.0, 1.5, 2.0]))
/// let acos = series.acos()
/// ```
pub fn Series::acos(self : Series) -> Series!InvalidType {
  match self.data {
    SeriesData::Int(data) =>
      Series::new(
        self.name,
        SeriesInput::Float32(
          data.map(fn(x) { @math.acos(x.to_double()).to_float() }),
        ),
      )
    SeriesData::Float(data) =>
      Series::new(
        self.name,
        SeriesInput::Float32(
          data.map(fn(x) { @math.acos(x.to_double()).to_float() }),
        ),
      )
    _ => raise InvalidType("unsupported type")
  }
}

///| Compute the logarithm to a given base.
/// Parameters
/// 
/// - `base` : The base of the logarithm. Default is Euler's number (e).
/// 
/// Example
/// ```
/// let series = Series::new("test", SeriesInput::Float32([1.0, 1.5, 2.0]))
/// let log = series.log()
/// let log10 = series.log(base = 10)
/// ```
pub fn Series::log(
  self : Series,
  base~ : Float = 2.718281828459045
) -> Series!InvalidType {
  match self.data {
    SeriesData::Int(data) =>
      Series::new(
        self.name,
        SeriesInput::Float32(
          data.map(fn(x) {
            (@math.ln(x.to_double()) / @math.ln(base.to_double())).to_float()
          }),
        ),
      )
    SeriesData::Float(data) =>
      Series::new(
        self.name,
        SeriesInput::Float32(
          data.map(fn(x) {
            (@math.ln(x.to_double()) / @math.ln(base.to_double())).to_float()
          }),
        ),
      )
    _ => raise InvalidType("unsupported type")
  }
}

///| Compute the base 10 logarithm of the input array, element-wise.
/// 
/// Example
/// ```
/// let series = Series::new("test", SeriesInput::Float32([1.0, 1.5, 2.0]))
/// let log10 = series.log10()
/// ```
pub fn Series::log10(self : Series) -> Series!InvalidType {
  match self.data {
    SeriesData::Int(data) =>
      Series::new(
        self.name,
        SeriesInput::Float32(
          data.map(fn(x) { @math.log10(x.to_double()).to_float() }),
        ),
      )
    SeriesData::Float(data) =>
      Series::new(
        self.name,
        SeriesInput::Float32(
          data.map(fn(x) { @math.log10(x.to_double()).to_float() }),
        ),
      )
    _ => raise InvalidType("unsupported type")
  }
}
