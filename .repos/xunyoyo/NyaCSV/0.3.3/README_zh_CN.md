# 🐱NyaCSV 

> *完美解析你的CSV文件，带来愉悦的简洁体验！*

[English](https://github.com/moonbit-community/NyaCSV/blob/main/README.md) | [简体中文](https://github.com/moonbit-community/NyaCSV/blob/main/README_zh_CN.md)

[![构建状态](https://img.shields.io/github/actions/workflow/status/moonbit-community/NyaCSV/ci.yml)](https://github.com/moonbit-community/NyaCSV/actions)
[![许可证](https://img.shields.io/github/license/moonbit-community/NyaCSV)](LICENSE)
[![代码覆盖率](https://codecov.io/gh/moonbit-community/NyaCSV/branch/main/graph/badge.svg)](https://codecov.io/gh/moonbit-community/NyaCSV)

喵CSV是一个趣味十足且功能强大的MoonBit CSV解析和操作库，以猫一般的优雅和精准处理你的数据。告别数据乱麻，迎接优雅结构化的信息！

## ✨ 特性

- **多源输入** - 从字符串、二进制数据或缓冲区解析CSV...好奇的猫咪能找到的任何数据格式！
- **自定义分隔符** - 不只是逗号！使用任何字符分隔你的字段（因为猫咪从不遵循规则）
- **智能引号处理** - 专业处理包含特殊字符的引用字段，就像猫咪小心翼翼地叼着它最喜欢的玩具
- **表头管理** - 以猫科动物的智慧自动检测或生成列标题
- **空白整理** - 可选择修剪前后空格，让你的数据像精心梳理过的猫咪一样整洁
- **精美打印输出** - 以漂亮的表格格式显示数据，任何猫咪都会为之自豪地展示
- **灵活配置** - 自定义解析行为以满足你的确切需求，如同最挑剔的猫咪一般苛求

## 🚀 快速开始

```moonbit
fn main() {
  // 解析简单的CSV字符串
  let data = "名字,年龄,最喜欢的玩具\n小咪,3,毛线球\n胡须,5,激光笔"
  let csv = CSV::parse_string(data)
  
  // 显示为漂亮的表格
  println!("{}", csv)
  
  // 直接访问数据
  println!("第一只猫的名字是: {}", csv.rows[0][0])
}
```

## 📦 安装

将喵CSV添加到你的MoonBit项目中：

```bash
moon add xunyoyo/NyaCSV
```

## 🧶 使用示例

### 使用自定义选项解析CSV

```moonbit
let options : CSVOptions = {
  delimiter: ';',
  allow_newlines_in_quotes: true,
  quote_char: '"',
  skip_empty_lines: true,
  trim_spaces: true
}

let cat_data = "名字;描述;已领养\n辛巴;\"顽皮的橙色虎斑猫\n爱吃零食\";是"
let csv = CSV::parse_string(cat_data, options~)
```

### 从零开始创建CSV

```moonbit
// 从空CSV开始
let csv = CSV::new()

// 以编程方式添加标题和数据
// ...

// 转换回字符串
let csv_string = csv.to_string()
```

### 使用二维数组

```moonbit
let cat_shelter_data = [
  ["名字", "年龄", "颜色", "已领养"],
  ["露娜", "2", "黑色", "是"],
  ["奥利弗", "1", "虎斑", "否"],
  ["贝拉", "4", "三色", "是"]
]

let csv = CSV::from_array(cat_shelter_data)
println!("{}", csv)
```

## 🔍 API参考

### 核心结构

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
  delimiter : Char              // 默认: ','
  allow_newlines_in_quotes : Bool  // 默认: true
  quote_char : Char             // 默认: '"'
  skip_empty_lines : Bool       // 默认: true
  trim_spaces : Bool            // 默认: false
}
```

### 解析方法

- **`CSV::parse_string(data: String, options: CSVOptions) -> CSV`** - 从字符串解析CSV
- **`CSV::parse_buffer(data: Buffer, options: CSVOptions) -> CSV`** - 从缓冲区解析CSV
- **`CSV::parse_bytes(data: Bytes, options: CSVOptions) -> CSV`** - 从字节解析CSV

### 创建方法

- **`CSV::new() -> CSV`** - 创建空CSV
- **`CSV::from_array(data: Array[Array[String]], has_header: Bool = true, generate_headers: Bool = true) -> CSV`** - 从二维数组创建CSV

### 显示方法

- **`to_string() -> String`** - 将CSV转换回字符串格式
- **`output(logger) -> Unit`** - 显示为格式精美的表格

## 🎭 高级示例

### 创建精美表格

```moonbit
let cat_breeds = "品种,产地,体型,性格\n暹罗猫,泰国,中等,\"爱叫,活跃\"\n缅因猫,美国,大型,\"温柔,顽皮\"\n布偶猫,美国,大型,\"冷静,亲昵\""

let csv = CSV::parse_string(cat_breeds)

// 打印为精美表格
println!("{}", csv)

// 输出:
// +-----------+--------+--------+------------------+
// | 品种       | 产地    | 体型   | 性格              |
// +-----------+--------+--------+------------------+
// | 暹罗猫     | 泰国    | 中等   | 爱叫, 活跃         |
// | 缅因猫     | 美国    | 大型   | 温柔, 顽皮         |
// | 布偶猫     | 美国    | 大型   | 冷静, 亲昵         |
// +-----------+--------+--------+------------------+
```

### 处理多行字段

```moonbit
let cat_profiles = "名字,简介\n露西,\"露西是一只好奇的猫。\n她喜欢探索。\"\n马克斯,\"马克斯很懒。\n他整天睡觉。\""

let csv = CSV::parse_string(cat_profiles)
println!("{}", csv)
```

## 🐾 贡献

欢迎贡献！随时提交问题和拉取请求，帮助使喵CSV变得更加完美。

## 📜 许可证

Apache-2.0

---

*由爱猫人士为数据爱好者精心制作 <3*
