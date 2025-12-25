require 'active_record'
require 'activerecord-import'
require 'active_support/core_ext/array/grouping'
require 'logger'
require 'pp'

module Arison
  # Core class handles database operations and schema management
  class Core
    attr_reader :connection

    # Initialize Core with database profile
    # @param profile [Hash] Database connection configuration
    # @raise [ArgumentError] if profile is invalid
    def initialize(profile)
      validate_profile!(profile)

      @profile = profile
      ActiveRecord::Base.establish_connection(@profile)
      @connection = ActiveRecord::Base.connection
      @logger = Logger.new(STDOUT)
    end

    # Execute SQL query and return results
    # @param sql [String] SQL query to execute
    # @return [Array<Hash>] Query results
    def query(sql)
      @connection.exec_query(sql).to_a
    end

    # Get column information for a table
    # @param table_name [String] Table name
    # @return [Array<Hash>] Column information
    def columns_with_table_name(table_name)
      columns(get_class(table_name))
    end

    # Get column information from model class
    # @param klass [Class] ActiveRecord model class
    # @return [Array<Hash>] Column information
    def columns(klass)
      klass.columns.map do |column|
        JSON.parse(column.to_json)
      end
    end

    # Get list of all tables
    # @return [Array<String>] Table names
    def tables
      @connection.tables
    end

    # Import data into table with automatic schema creation
    # @param table_name [String] Target table name
    # @param data [Array<Hash>] Data to import
    # @raise [ArgumentError] if data is invalid
    def import(table_name, data)
      validate_import_data!(data)

      create_table(table_name, data)
      klass = get_class(table_name)
      limits = get_limit_hash(klass)
      instances = build_instances(klass, data, limits)

      import_in_batches(klass, instances)
    end

    private

    # Validate database profile
    # @param profile [Hash] Database configuration
    # @raise [ArgumentError] if profile is invalid
    def validate_profile!(profile)
      raise ArgumentError, "Profile must be a Hash" unless profile.is_a?(Hash)
      raise ArgumentError, "Profile must contain 'adapter'" unless profile.key?('adapter') || profile.key?(:adapter)
    end

    # Validate import data
    # @param data [Array] Data to validate
    # @raise [ArgumentError] if data is invalid
    def validate_import_data!(data)
      raise ArgumentError, "Data must be an Array" unless data.is_a?(Array)
      raise ArgumentError, "Data cannot be empty" if data.empty?
    end

    # Build ActiveRecord instances from data
    # @param klass [Class] ActiveRecord model class
    # @param data [Array<Hash>] Data to convert
    # @param limits [Hash] Column length limits
    # @return [Array] ActiveRecord instances
    def build_instances(klass, data, limits)
      instances = []
      data.each do |record|
        instance = klass.new
        begin
          record = sanitize_record(record, limits)
          instance.attributes = record
        rescue ActiveRecord::UnknownAttributeError => e
          @logger.warn("Unknown attribute: #{e.message}")
        rescue => e
          @logger.error("#{e.message}\n#{e.backtrace.join("\n")}")
        ensure
          instances << instance
        end
      end
      instances
    end

    # Sanitize record data based on column limits
    # @param record [Hash] Record data
    # @param limits [Hash] Column length limits
    # @return [Hash] Sanitized record
    def sanitize_record(record, limits)
      record.inject({}) do |result, (k, v)|
        length = limits[k]
        result[k] = if (v.class == Array || v.class == Hash)
          v.to_json
        elsif (length.nil? || v.nil? || v.class != String)
          v
        else
          v.slice(0, length)
        end
        result
      end
    end

    # Import instances in batches
    # @param klass [Class] ActiveRecord model class
    # @param instances [Array] ActiveRecord instances
    def import_in_batches(klass, instances, batch_size: 10000)
      instances.in_groups_of(batch_size, false) do |block|
        begin
          klass.import(block)
        rescue => e
          @logger.error("Import failed for batch")
          pp block
          @logger.error("#{e.message}\n#{e.backtrace.join("\n")}")
          raise
        end
      end
    end

    # Generate CREATE TABLE DSL
    # @param table_name [String] Table name
    # @param hash [Hash] Sample data hash for schema inference
    # @return [String] Migration DSL string
    def get_create_table_dsl(table_name, hash)
      dsl = %Q{
      create_table "#{table_name}" do |t|
        #{get_column_schema(hash).join("\n")}
        t.datetime "created_at"
        t.datetime "updated_at"
      end
      }
    end

    # Generate ADD INDEX DSL
    # @param table_name [String] Table name
    # @param uniq_columns [Array<String>] Column names for unique index
    # @return [String] Migration DSL string
    def get_add_index_dsl(table_name, uniq_columns)
      dsl = %Q{
      add_index(:#{table_name}, #{uniq_columns.map(&:to_sym)}, unique: true)
      }
    end

    # Generate ADD COLUMN DSL
    # @param table_name [String] Table name
    # @param column_name [String] Column name
    # @param record [Hash] Record containing column data
    # @return [String] Migration DSL string
    def get_add_column_dsl(table_name, column_name, record)
      dsl = %Q{
      add_column "#{table_name}", "#{column_name}", :#{Util.get_type(column_name, record[column_name])}
      }
    end

    # Create table if not exists, or add columns if exists
    # @param table_name [String] Table name
    # @param data [Array<Hash>] Data for schema inference
    def create_table(table_name, data)
      first = data.class == Array ? data.first : data
      if ActiveRecord::Base.connection.data_source_exists?(table_name.to_sym)
        add_column_live(table_name, data)
        return
      end
      create_table_dsl = get_create_table_dsl(table_name, first)
      Arison::Migration.run_dsl(create_table_dsl)
      add_column_live(table_name, data)
    end

    # Get or create ActiveRecord model class for table
    # @param table_name [String] Table name
    # @return [Class] ActiveRecord model class
    def get_class(table_name)
      define_class(table_name)
      table_name.camelcase.constantize
    end

    # Define ActiveRecord model class dynamically
    # @param table_name [String] Table name
    # @return [Class] Defined class
    def define_class(table_name)
      klass_sym = table_name.camelcase.to_sym
      if Object.constants.include?(klass_sym)
        Object.send(:remove_const, klass_sym)
      end
      Object.const_set(table_name.camelcase, Class.new(ActiveRecord::Base) do
        self.table_name = table_name
      end)
    end

    # Generate column schema from hash
    # @param hash [Hash] Sample data hash
    # @return [Array<String>] Column definition strings
    def get_column_schema(hash)
      hash.map do |k, v|
        type = Util.get_type(k, v)
        %Q{t.#{type} "#{k}"} unless type.nil?
      end
    end

    # Get column length limits as hash
    # @param klass [Class] ActiveRecord model class
    # @return [Hash] Column name => limit mapping
    def get_limit_hash(klass)
      columns(klass).inject({}) do |result, column|
        result[column['name']] = column['limit']
        result
      end
    end

    # Add new columns to existing table dynamically
    # @param table_name [String] Table name
    # @param data [Array<Hash>] Data containing new columns
    def add_column_live(table_name, data)
      data.each do |record|
        limits = get_limit_hash(get_class(table_name))
        record = Hash[record.map { |k,v| [k.to_s,v] }]
        diff_keys = (record.keys - limits.keys)

        diff_keys.each do |column|
          add_column_dsl = get_add_column_dsl(table_name, column, record)
          Arison::Migration.run_dsl(add_column_dsl)
        end
        ActiveRecord::Base.establish_connection(@profile)
      end
    end
  end
end
