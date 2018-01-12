require 'spec_helper'
require 'arison'
require 'fileutils'

describe Arison::Core do

  before(:all) do
    FileUtils.rm( 'tmp/core.db', {:force=>true} )
    @core = get_core
  end

  it "core not nil" do
    @core.should_not nil
  end

  it "core import" do
    data = [
      { "column_1" => 1, "column_2" => "string_1", "column_3" => 0.1 },
      { "column_1" => 2, "column_2" => "string_2" },
    ]
    get_core.import('test', data)
  end

  it "core query record 1" do
    results = get_core.query('select * from test')
    record = results.first
    expect(record['id']).to eq(1)
    expect(record['column_1']).to eq(1)
    expect(record['column_2']).to eq("string_1")
    expect(record['column_3']).to eq(0.1)
  end

  it "core query record 2" do
    results = get_core.query('select * from test')
    record = results[1]
    expect(record['id']).to eq(2)
    expect(record['column_1']).to eq(2)
    expect(record['column_2']).to eq("string_2")
    expect(record['column_3']).to eq(nil)
  end

  it "core columns" do
    columns = get_core.columns_with_table_name("test")
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

  after(:all) do
  end
end
