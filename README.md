# arison [![Build Status](https://secure.travis-ci.org/toyama0919/arison.png?branch=master)](http://travis-ci.org/toyama0919/arison)

A tool that predicts schema from data and easily populates the database.

## Examples Settings

For example, set the following.

```yaml
mydb:
  adapter: sqlite3
  database: /app/sqlite/suggest.db
  pool: 5
  timeout: 5000
```

Execute code like below.

```ruby
require 'arison'
Arison.import(
  "my_table",
  [
    { column1: "test", column2: Time.now.to_i },
    { column1: "test2", column2: Time.now.to_i },
  ],
  profile: "mydb"
)
```

Then it looks like

```
sqlite> select * from my_table ;
1|test|1607692573|2020-12-11 22:16:14.123455|2020-12-11 22:16:14.123455
2|test2|1607692573|2020-12-11 22:16:14.123455|2020-12-11 22:16:14.123455
```

* Automatically generate table, and also generate column from data.
* created_at and updated_at are also automatically created.


## Command Line Interface

```bash
arison -b -p mydb -t my_table --data column1:"test" column2:1
```

## Installation

Add this line to your application's Gemfile:

    gem 'arison'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install arison

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new [Pull Request](../../pull/new/master)

## Information

* [Homepage](https://github.com/toyama0919/arison)
* [Issues](https://github.com/toyama0919/arison/issues)
* [Documentation](http://rubydoc.info/gems/arison/frames)
* [Email](mailto:toyama0919@gmail.com)

## Copyright

Copyright (c) 2014 Hiroshi Toyama

See [LICENSE.txt](../LICENSE.txt) for details.
