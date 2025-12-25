# -*- coding: utf-8 -*-
require "thor"
require 'json'
require 'pp'

module Arison
  class CLI < Thor

    map '--version' => :version
    map '-s' => :query
    map '-b' => :import

    class_option :profile, aliases: '-p', type: :string, default: DEFAULT_CONFIG_PROFILE, desc: 'Database profile name from config file'
    class_option :pretty, aliases: '-P', type: :boolean, default: false, desc: 'Pretty print JSON output'
    class_option :config, aliases: '--config', type: :string, default: DEFAULT_CONFIG_FILE_PATH, desc: 'Path to config file (default: ~/.arison.yml or ./.arison.yml)'
    def initialize(args = [], options = {}, config = {})
      super(args, options, config)
      @global_options = config[:shell].base.options

      if @global_options[:config] && File.exist?(@global_options[:config])
        profile = Util.get_profile(@global_options[:config], @global_options[:profile])
        if profile
          @core = Core.new(profile)
        end
      end
    end

    desc 'query', 'Execute SQL query and return results as JSON'
    long_desc <<-LONGDESC
      Execute a SQL query against the database and output results in JSON format.

      Query can be provided via:
      - Command line argument with -q/--query option
      - File path with -f/--file option
      - Standard input (pipe)

      Examples:
        $ arison query -p mydb -q "SELECT * FROM users WHERE age > 25"
        $ arison query -p mydb -f query.sql
        $ echo "SELECT * FROM users LIMIT 10" | arison query -p mydb
    LONGDESC
    option :query, aliases: '-q', type: :string, desc: 'SQL query string to execute'
    option :file, aliases: '-f', type: :string, desc: 'Path to SQL file to execute'
    def query
      file_sql = if options[:file] && File.exist?(options[:file])
        File.read(options[:file])
      end
      query = options[:query] || file_sql || STDIN.read
      puts_json @core.query(query)
    end

    desc 'tables', 'List all tables in the database'
    long_desc <<-LONGDESC
      Display a list of all tables in the configured database.
      Output is in JSON format.

      Example:
        $ arison tables -p mydb
    LONGDESC
    def tables
      puts_json @core.tables
    end

    desc 'columns', 'Show column information for a specific table'
    long_desc <<-LONGDESC
      Display detailed column information (name, type, limit, etc.) for a specified table.
      Output includes column name, SQL type, limit, default value, and other metadata.

      Example:
        $ arison columns -p mydb -t users
    LONGDESC
    option :table, aliases: '-t', type: :string, required: true, desc: 'Table name to inspect'
    def columns
      puts_json @core.columns_with_table_name(options[:table])
    end

    desc 'import', 'Import JSON/JSONL data into database with automatic schema creation'
    long_desc <<-LONGDESC
      Import data into the specified table. If the table doesn't exist, it will be created automatically.
      If new columns are detected in the data, they will be added to the existing table.

      Data can be provided via:
      - Command line with --data option (key:value pairs)
      - Standard input as JSON or JSONL format

      Examples:
        # Import single record from command line
        $ arison import -p mydb -t users --data name:"Alice" age:30 email:"alice@example.com"

        # Import from JSON file
        $ cat data.json | arison import -p mydb -t users

        # Import from JSONL file (one JSON object per line)
        $ cat data.jsonl | arison import -p mydb -t users
    LONGDESC
    option :table, aliases: '-t', type: :string, required: true, desc: 'Target table name for import'
    option :data, type: :hash, desc: 'Data to import as key:value pairs'
    def import
      data = (options[:data] ? options[:data] : nil) || Util.parse_json(STDIN.read)
      data = [data] if data.class == Hash
      @core.import(options[:table], data)
    end

    desc 'info', 'Display current configuration information'
    long_desc <<-LONGDESC
      Show the current database configuration being used.
      Useful for debugging connection issues.

      Example:
        $ arison info -p mydb
    LONGDESC
    def info
      puts_json @config
    end

    desc 'version', 'Show arison version'
    def version
      puts VERSION
    end

    private
    def puts_json(object)
      puts JSON.pretty_generate(object)
    end
  end
end
