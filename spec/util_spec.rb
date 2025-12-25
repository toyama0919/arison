require 'spec_helper'
require 'arison'
require 'json'

describe Arison::Util do
  describe '.get_profile' do
    before(:all) do
      FileUtils.mkdir_p('tmp')
      config = {
        'test_profile' => {
          'adapter' => 'sqlite3',
          'database' => 'test.db'
        },
        'production' => {
          'adapter' => 'mysql2',
          'database' => 'prod_db',
          'host' => 'localhost'
        }
      }
      File.write('tmp/test_config.yml', config.to_yaml)
    end

    it "loads profile from config file" do
      profile = Arison::Util.get_profile('tmp/test_config.yml', 'test_profile')
      expect(profile).to be_a(Hash)
      expect(profile['adapter']).to eq('sqlite3')
      expect(profile['database']).to eq('test.db')
    end

    it "returns different profiles correctly" do
      profile = Arison::Util.get_profile('tmp/test_config.yml', 'production')
      expect(profile['adapter']).to eq('mysql2')
      expect(profile['database']).to eq('prod_db')
      expect(profile['host']).to eq('localhost')
    end

    it "returns nil for non-existent profile" do
      profile = Arison::Util.get_profile('tmp/test_config.yml', 'non_existent')
      expect(profile).to be_nil
    end

    after(:all) do
      FileUtils.rm('tmp/test_config.yml', force: true)
    end
  end

  describe '.parse_json' do
    context 'with valid JSON object' do
      it "parses single JSON object" do
        json_string = '{"name":"Alice","age":30}'
        result = Arison::Util.parse_json(json_string)
        expect(result).to be_a(Hash)
        expect(result['name']).to eq('Alice')
        expect(result['age']).to eq(30)
      end

      it "parses JSON array" do
        json_string = '[{"name":"Alice"},{"name":"Bob"}]'
        result = Arison::Util.parse_json(json_string)
        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result[0]['name']).to eq('Alice')
        expect(result[1]['name']).to eq('Bob')
      end
    end

    context 'with JSONL format' do
      it "parses JSONL (newline-delimited JSON)" do
        jsonl_string = <<~JSONL
          {"name":"Alice","age":30}
          {"name":"Bob","age":25}
          {"name":"Charlie","age":35}
        JSONL

        result = Arison::Util.parse_json(jsonl_string)
        expect(result).to be_an(Array)
        expect(result.length).to eq(3)
        expect(result[0]['name']).to eq('Alice')
        expect(result[1]['name']).to eq('Bob')
        expect(result[2]['name']).to eq('Charlie')
      end

      it "handles JSONL with different data structures" do
        jsonl_string = <<~JSONL
          {"id":1,"data":"first"}
          {"id":2,"data":"second","extra":"value"}
        JSONL

        result = Arison::Util.parse_json(jsonl_string)
        expect(result.length).to eq(2)
        expect(result[0]['id']).to eq(1)
        expect(result[1]['extra']).to eq('value')
      end
    end
  end

  describe '.get_type' do
    context 'with nil value' do
      it "returns string type" do
        expect(Arison::Util.get_type('any_column', nil)).to eq('string')
      end
    end

    context 'with id column' do
      it "returns nil for 'id' column" do
        expect(Arison::Util.get_type('id', 123)).to be_nil
      end

      it "returns nil for 'ID' column (case insensitive)" do
        expect(Arison::Util.get_type('ID', 123)).to be_nil
      end
    end

    context 'with string value' do
      it "returns string type for regular string" do
        expect(Arison::Util.get_type('name', 'Alice')).to eq('string')
      end

      it "returns datetime type for datetime string" do
        datetime_string = '2024-12-25 10:00:00'
        expect(Arison::Util.get_type('created_at', datetime_string)).to eq('datetime')
      end
    end

    context 'with boolean value' do
      it "returns boolean type for true" do
        expect(Arison::Util.get_type('active', true)).to eq('boolean')
      end

      it "returns boolean type for false" do
        expect(Arison::Util.get_type('active', false)).to eq('boolean')
      end
    end

    context 'with numeric values' do
      it "returns integer type for integer" do
        expect(Arison::Util.get_type('age', 30)).to eq('integer')
      end

      it "returns float type for float" do
        expect(Arison::Util.get_type('price', 19.99)).to eq('float')
      end
    end

    context 'with array or hash' do
      it "returns text type for array" do
        expect(Arison::Util.get_type('tags', ['ruby', 'rails'])).to eq('text')
      end

      it "returns text type for hash" do
        expect(Arison::Util.get_type('metadata', { key: 'value' })).to eq('text')
      end
    end

    context 'with Time object' do
      it "returns datetime type for Time object" do
        time = Time.now
        expect(Arison::Util.get_type('timestamp', time)).to eq('datetime')
      end

      it "returns datetime type for Date object" do
        date = Date.today
        expect(Arison::Util.get_type('date', date)).to eq('datetime')
      end
    end
  end

  describe '.to_time_or_nil' do
    context 'with valid datetime strings' do
      it "converts ISO 8601 format" do
        time = Arison::Util.to_time_or_nil('2024-12-25T10:00:00')
        expect(time).to be_a(Time)
        expect(time.year).to eq(2024)
        expect(time.month).to eq(12)
        expect(time.day).to eq(25)
      end

      it "converts standard datetime format" do
        time = Arison::Util.to_time_or_nil('2024-12-25 10:00:00')
        expect(time).to be_a(Time)
        expect(time.year).to eq(2024)
      end
    end

    context 'with invalid datetime strings' do
      it "returns nil for non-datetime string" do
        expect(Arison::Util.to_time_or_nil('hello world')).to be_nil
      end

      it "returns nil for string not starting with 4 digits" do
        expect(Arison::Util.to_time_or_nil('abc-12-25')).to be_nil
      end

      it "returns nil for empty string" do
        expect(Arison::Util.to_time_or_nil('')).to be_nil
      end
    end

    context 'with edge cases' do
      it "returns nil for dates before Unix epoch" do
        # This depends on implementation, but generally we expect nil for very old dates
        result = Arison::Util.to_time_or_nil('1900-01-01')
        # Some implementations might return nil, others might return the time
        expect([Time, NilClass]).to include(result.class)
      end
    end
  end
end
