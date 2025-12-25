require 'spec_helper'
require 'arison'
require 'fileutils'

describe Arison::Core do

  before(:all) do
    FileUtils.mkdir_p('tmp')
    FileUtils.rm('tmp/core.db', force: true)
    @core = get_core
  end

  describe '#initialize' do
    it "creates a core instance" do
      expect(@core).not_to be_nil
    end

    it "establishes database connection" do
      expect(@core.instance_variable_get(:@connection)).not_to be_nil
    end

    it "raises error with invalid profile" do
      expect {
        Arison::Core.new(nil)
      }.to raise_error(ArgumentError, /Profile must be a Hash/)
    end

    it "raises error with profile missing adapter" do
      expect {
        Arison::Core.new({})
      }.to raise_error(ArgumentError, /Profile must contain 'adapter'/)
    end
  end

  describe '#import' do
    it "imports data with various column types" do
      data = [
        { "column_1" => 1, "column_2" => "string_1", "column_3" => 0.1 },
        { "column_1" => 2, "column_2" => "string_2" },
      ]
      expect {
        @core.import('test', data)
      }.not_to raise_error
    end

    it "handles array data" do
      data = [
        { "name" => "Alice", "tags" => ["ruby", "rails"] }
      ]
      expect {
        @core.import('test_arrays', data)
      }.not_to raise_error
    end

    it "handles hash data" do
      data = [
        { "name" => "Bob", "metadata" => { "city" => "Tokyo", "age" => 30 } }
      ]
      expect {
        @core.import('test_hashes', data)
      }.not_to raise_error
    end

    it "handles large datasets" do
      large_data = 1000.times.map do |i|
        { "id_value" => i, "name" => "User #{i}" }
      end
      expect {
        @core.import('test_large', large_data)
      }.not_to raise_error
    end

    it "raises error for non-array data" do
      expect {
        @core.import('invalid', "not an array")
      }.to raise_error(ArgumentError, /Data must be an Array/)
    end

    it "raises error for empty data" do
      expect {
        @core.import('invalid', [])
      }.to raise_error(ArgumentError, /Data cannot be empty/)
    end
  end

  describe '#query' do
    it "returns first record correctly" do
      core = get_core
      results = core.query('select * from test ORDER BY id')
      record = results.first
      expect(record['id']).to eq(1)
      expect(record['column_1']).to eq(1)
      expect(record['column_2']).to eq("string_1")
      expect(record['column_3']).to eq(0.1)
    end

    it "returns second record correctly" do
      core = get_core
      results = core.query('select * from test ORDER BY id')
      record = results[1]
      expect(record['id']).to eq(2)
      expect(record['column_1']).to eq(2)
      expect(record['column_2']).to eq("string_2")
      expect(record['column_3']).to be_nil
    end

    it "returns filtered results" do
      core = get_core
      results = core.query('select * from test where column_1 = 1')
      expect(results.length).to eq(1)
      expect(results.first['column_1']).to eq(1)
    end

    it "handles count queries" do
      core = get_core
      results = core.query('select count(*) as count from test')
      expect(results.first['count']).to be >= 2
    end

    it "handles aggregate queries" do
      core = get_core
      results = core.query('select sum(column_1) as total from test')
      expect(results.first['total']).to be >= 3
    end
  end

  describe '#columns_with_table_name' do
    it "returns correct column information" do
      columns = @core.columns_with_table_name("test")

      expect(columns[0]['name']).to eq('id')
      expect(columns[0]['sql_type_metadata']['type']).to eq('integer')

      expect(columns[1]['name']).to eq('column_1')
      expect(columns[1]['sql_type_metadata']['type']).to eq('integer')

      expect(columns[2]['name']).to eq('column_2')
      expect(columns[2]['sql_type_metadata']['type']).to eq('string')

      expect(columns[3]['name']).to eq('column_3')
      expect(columns[3]['sql_type_metadata']['type']).to eq('float')

      expect(columns[4]['name']).to eq('created_at')
      expect(columns[4]['sql_type_metadata']['type']).to eq('datetime')

      expect(columns[5]['name']).to eq('updated_at')
      expect(columns[5]['sql_type_metadata']['type']).to eq('datetime')
    end

    it "returns array of hashes" do
      columns = @core.columns_with_table_name("test")
      expect(columns).to be_an(Array)
      expect(columns.first).to be_a(Hash)
    end
  end

  describe '#tables' do
    it "returns list of tables" do
      core = get_core
      tables = core.tables
      expect(tables).to be_an(Array)
      expect(tables).to include('test')
    end

    it "includes all created tables" do
      core = get_core
      core.import('new_table', [{ "col" => "value" }])

      # Create new instance to verify
      core2 = get_core
      tables = core2.tables
      expect(tables).to include('new_table')
    end
  end

  describe '#create_table' do
    it "creates table with correct schema" do
      core = get_core
      data = [{ "name" => "Test", "value" => 123 }]
      core.import('auto_created', data)

      # Create new instance to verify
      core2 = get_core
      expect(core2.tables).to include('auto_created')
    end

    it "adds new columns to existing table" do
      core = get_core
      core.import('dynamic_table', [{ "col1" => "value1" }])
      core.import('dynamic_table', [{ "col1" => "value2", "col2" => "value2" }])

      columns = core.columns_with_table_name('dynamic_table')
      column_names = columns.map { |c| c['name'] }
      expect(column_names).to include('col1', 'col2')
    end
  end

  describe 'data type inference' do
    before(:all) do
      data = [
        {
          "int_col" => 42,
          "float_col" => 3.14,
          "string_col" => "hello",
          "bool_col" => true,
          "time_col" => Time.now
        }
      ]
      @core.import('type_test', data)
    end

    it "correctly infers integer type" do
      columns = @core.columns_with_table_name('type_test')
      int_col = columns.find { |c| c['name'] == 'int_col' }
      expect(int_col['sql_type_metadata']['type']).to eq('integer')
    end

    it "correctly infers float type" do
      columns = @core.columns_with_table_name('type_test')
      float_col = columns.find { |c| c['name'] == 'float_col' }
      expect(float_col['sql_type_metadata']['type']).to eq('float')
    end

    it "correctly infers string type" do
      columns = @core.columns_with_table_name('type_test')
      string_col = columns.find { |c| c['name'] == 'string_col' }
      expect(string_col['sql_type_metadata']['type']).to eq('string')
    end
  end

  after(:all) do
    FileUtils.rm('tmp/core.db', force: true)
  end
end
