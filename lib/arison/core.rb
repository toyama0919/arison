require 'active_record'
require 'activerecord-import'
require 'active_support'

module Arison
  class Core

    def initialize(profile)
      @profile = profile
      ActiveRecord::Base.establish_connection(@profile)
      ActiveRecord::Base.default_timezone = :local
      @connection = ActiveRecord::Base.connection
    end

    def query(sql)
    	@connection.exec_query(sql).to_a
    end

    def columns_with_table_name(table_name)
      columns(get_class(table_name))
    end

    def columns(klass)
      klass.columns.map do |column|
        JSON.parse(column.to_json)
      end
    end

    def tables
      @connection.tables
    end

    def import(table_name, data)
      klass = get_class(table_name)
      limits = get_limit_hash(klass)
      instances = []
      data.each do |record|
        instance = klass.new
        begin
          record = record.inject({}){ |result, (k, v)|
            length = limits[k]
            result[k] = (length.nil? || v.nil? || v.class != String) ? v : v.slice(0, length)
            result
          }
          instance.attributes = record
        rescue ActiveRecord::UnknownAttributeError => e
        rescue => e
          puts "\n#{e.message}\n#{e.backtrace.join("\n")}"
        ensure
          instances << instance
        end
      end
      instances.in_groups_of(10000, false) do |block|
        klass.import(block)
      end
    end

    def get_create_table_dsl(table_name, hash)
      dsl = %Q{
      create_table "#{table_name}" do |t|
        #{get_column_schema(hash).join("\n")}
        t.datetime "created_at"
        t.datetime "updated_at"
      end
      }
    end

    def get_add_index_dsl(table_name, uniq_columns)
      dsl = %Q{
      add_index(:#{table_name}, #{uniq_columns.map(&:to_sym)}, unique: true)
      }
    end

    def get_add_column_dsl(table_name, column_name, record)
      dsl = %Q{
      add_column "#{table_name}", "#{column_name}", :#{get_type(column_name, record['column_name'])}
      }
    end

    def create_table(table_name, data)
      first = data.class == Array ? data.first : data
      if @connection.data_source_exists?(table_name)
        add_column_live(table_name, data)
        return 
      end
      create_table_dsl = get_create_table_dsl(table_name, first)
      Arison::Migration.run_dsl(create_table_dsl)
      add_column_live(table_name, data)
    end

    def parse_json(buffer)
      begin
        data = JSON.parse(buffer)
      rescue => e
        data = []
        buffer.lines.each do |line|
          data << JSON.parse(line)
        end
      end
      data
    end

    def get_class(table_name)
      define_class(table_name)
      table_name.camelcase.constantize
    end

    def define_class(table_name)
      klass_sym = table_name.camelcase.to_sym
      if Object.constants.include?(klass_sym)
        Object.send(:remove_const, klass_sym)
      end
      Object.const_set(table_name.camelcase, Class.new(ActiveRecord::Base) do
        self.table_name = table_name
      end)
    end

    def get_column_schema(hash)
      hash.map do |k, v|
        type = get_type(k, v)
        %Q{t.#{type} "#{k}"} unless type.nil?
      end
    end

    def get_type(k, v)
      if v.nil?
        %Q{string}
      elsif k =~ /^id$/i
        nil
      elsif v.class == String
        to_time_or_nil(v).nil? ? %Q{string} : %Q{datetime}
      elsif v.class == TrueClass || v.class == FalseClass
        %Q{boolean}
      elsif v.class == Fixnum
        %Q{integer}
      elsif v.class == Float
        %Q{float}
      elsif v.class == Array || v.class == Hash
        %Q{text}
      elsif v.respond_to?(:strftime)
        %Q{datetime}
      end
    end

    def to_time_or_nil(value)
      return nil if value.slice(0, 4) !~ /^[0-9][0-9][0-9][0-9]/
      begin
        time = value.to_time
        time.to_i >= 0 ? time : nil
      rescue => e
        nil
      end
    end

    def get_limit_hash(klass)
      columns(klass).inject({}){ |result, column| 
        result[column['name']] = column['limit']
        result
      }
    end

    def add_column_live(table_name, data)
      data.each do |record|
        limits = get_limit_hash(get_class(table_name))
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
