# arison

[![CI](https://github.com/toyama0919/arison/actions/workflows/ci.yml/badge.svg)](https://github.com/toyama0919/arison/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/arison.svg)](https://badge.fury.io/rb/arison)

A tool that automatically infers database schema from data and easily populates databases with bulk insert support.

## Features

- **Automatic Schema Inference**: Automatically generates table schemas from data types
- **Dynamic Column Addition**: Automatically adds new columns to existing tables
- **Bulk Insert Support**: High-speed data insertion using activerecord-import
- **JSONL Support**: Convenient for importing large datasets
- **Multiple Database Support**: Works with SQLite, MySQL, PostgreSQL, and all databases supported by ActiveRecord
- **CLI and Ruby API**: Provides both command-line interface and Ruby API

## Requirements

- Ruby >= 2.6.0
- ActiveRecord ~> 5.2

## Installation

Install as a gem:

```bash
$ gem install arison
```

Or add to your Gemfile:

```ruby
gem 'arison'
```

Then execute:

```bash
$ bundle install
```

## Configuration

Create database connection settings in `~/.arison.yml` or `./.arison.yml`:

```yaml
# SQLite example
mydb:
  adapter: sqlite3
  database: db/development.db
  pool: 5
  timeout: 5000

# MySQL example
production:
  adapter: mysql2
  encoding: utf8mb4
  database: my_database
  host: localhost
  username: root
  password: password
  pool: 5

# PostgreSQL example
postgres_db:
  adapter: postgresql
  encoding: unicode
  database: my_database
  host: localhost
  username: postgres
  password: password
  pool: 5
```

## Usage

### Ruby API

Basic usage:

```ruby
require 'arison'

# Import data
Arison.import(
  "users",
  [
    { name: "Alice", age: 30, email: "alice@example.com" },
    { name: "Bob", age: 25, email: "bob@example.com" },
  ],
  profile: "mydb"
)
```

Complex data types:

```ruby
# Supports strings, numbers, timestamps, arrays, hashes, etc.
Arison.import(
  "products",
  [
    {
      name: "Product A",
      price: 1000,
      stock: 50,
      tags: ["electronics", "popular"],
      metadata: { color: "red", size: "M" },
      created_date: Time.now
    },
    {
      name: "Product B",
      price: 2000,
      stock: 30,
      tags: ["clothing"],
      metadata: { color: "blue", size: "L" },
      created_date: Time.now
    }
  ],
  profile: "mydb"
)
```

Import from JSONL file:

```ruby
require 'arison'
require 'json'

# Read and import JSONL file
data = File.readlines('data.jsonl').map { |line| JSON.parse(line) }
Arison.import("my_table", data, profile: "mydb")
```

### Command Line Interface

Basic usage:

```bash
# Insert single record
arison -p mydb -t users --data name:"Alice" age:30 email:"alice@example.com"

# Batch mode for multiple records
arison -b -p mydb -t users --data name:"Bob" age:25
```

Import from JSONL file:

```bash
# Example data.jsonl:
# {"name":"Alice","age":30,"email":"alice@example.com"}
# {"name":"Bob","age":25,"email":"bob@example.com"}

cat data.jsonl | arison -p mydb -t users --jsonl
```

View all options:

```bash
arison --help
```

## Examples

### Automatic Table Creation

If the table doesn't exist, it will be created automatically:

```ruby
Arison.import("my_table", [{ column1: "test", column2: 123 }], profile: "mydb")
# => CREATE TABLE "my_table" (column1 TEXT, column2 INTEGER, created_at DATETIME, updated_at DATETIME)
```

### Dynamic Column Addition

New columns are automatically added to existing tables:

```ruby
# First import
Arison.import("my_table", [{ name: "Alice" }], profile: "mydb")

# Second import - 'age' column is automatically added
Arison.import("my_table", [{ name: "Bob", age: 30 }], profile: "mydb")
```

### Result

```sql
sqlite> SELECT * FROM my_table;
1|Alice||2024-12-25 10:00:00|2024-12-25 10:00:00
2|Bob|30|2024-12-25 10:01:00|2024-12-25 10:01:00
```

## Data Type Inference

arison infers data types using the following rules:

- Integer → `INTEGER`
- Float → `FLOAT`
- Boolean → `BOOLEAN`
- Time/DateTime → `DATETIME`
- Array/Hash → `TEXT` (stored as JSON)
- Others → `TEXT`

## Advanced Usage

### Direct Core API Usage

```ruby
require 'arison'

# Database connection
core = Arison::Core.new({
  adapter: 'sqlite3',
  database: 'db/development.db'
})

# List all tables
tables = core.tables

# Get column information
columns = core.columns_with_table_name('users')

# Execute raw SQL
result = core.query("SELECT * FROM users WHERE age > 25")
```

## Use Cases

### Data Analysis Prototyping

Quickly import CSV or JSON data into a database for analysis:

```ruby
require 'csv'
require 'arison'

# Load data from CSV
data = CSV.read('sales.csv', headers: true).map(&:to_h)

# Import to database
Arison.import('sales', data, profile: 'mydb')

# Analyze with SQL
core = Arison::Core.new(profile: 'mydb')
core.query("SELECT category, SUM(amount) FROM sales GROUP BY category")
```

### Log Data Storage

Store application logs in JSONL format to database:

```ruby
# Log collection script
File.open('app.log') do |f|
  logs = f.readlines.map { |line| JSON.parse(line) }
  Arison.import('application_logs', logs, profile: 'production')
end
```

### Test Data Generation

Insert dummy data for development and testing:

```ruby
# Generate large number of test users
test_users = 1000.times.map do |i|
  {
    name: "User #{i}",
    email: "user#{i}@example.com",
    age: rand(20..60),
    created_at: Time.now - rand(365).days
  }
end

Arison.import('users', test_users, profile: 'test')
```

## Performance Tips

- **Bulk Insert**: Large datasets are automatically split into batches of 10,000 records
- **Indexes**: Add indexes to frequently queried columns after import
- **Transactions**: activerecord-import automatically optimizes transactions

```ruby
# Efficient large dataset import
large_dataset = 100_000.times.map { |i| { id: i, value: rand } }
Arison.import('large_table', large_dataset, profile: 'mydb')
# => Automatically processes in batches of 10,000 records
```

## Troubleshooting

### Database Connection Error

```ruby
# Error: Could not find profile 'mydb'
# Solution: Add configuration to ~/.arison.yml or ./.arison.yml
```

### Column Length Limitation

Long strings are automatically truncated:

```ruby
# Automatically trimmed if VARCHAR(255) limit exists
Arison.import('users', [{ bio: "a" * 1000 }], profile: 'mydb')
```

### Type Mismatch

When inserting different data types into the same column:

```ruby
# If 'age' column was created as integer, inserting string will cause error
# Solution: Define table schema in advance or unify data types
```

## Development

Run tests:

```bash
bundle install
bundle exec rake spec
```

Local development:

```bash
# Build gem
gem build arison.gemspec

# Install locally
gem install ./arison-*.gem

# Run Rubocop
bundle exec rubocop
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new [Pull Request](../../pull/new/master)

## Links

* [Homepage](https://github.com/toyama0919/arison)
* [Issues](https://github.com/toyama0919/arison/issues)
* [RubyGems](https://rubygems.org/gems/arison)
* [Documentation](http://rubydoc.info/gems/arison/frames)

## License

Copyright (c) 2014-2024 Hiroshi Toyama

MIT License. See [LICENSE.txt](LICENSE.txt) for details.
