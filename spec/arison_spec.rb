require 'spec_helper'
require 'arison'

describe Arison do
  describe 'VERSION' do
    it "has a VERSION constant" do
      expect(Arison::VERSION).not_to be_empty
    end

    it "VERSION is a string" do
      expect(Arison::VERSION).to be_a(String)
    end

    it "VERSION matches semantic versioning format" do
      expect(Arison::VERSION).to match(/^\d+\.\d+\.\d+/)
    end
  end

  describe '.import' do
    before(:all) do
      FileUtils.mkdir_p('tmp')
      FileUtils.rm('tmp/arison_test.db', force: true)
    end

    it "imports data via Core directly" do
      profile = {
        adapter: "sqlite3",
        database: 'tmp/arison_test.db',
        timeout: 500
      }

      core = Arison::Core.new(profile)
      data = [
        { name: "Alice", age: 30 },
        { name: "Bob", age: 25 }
      ]

      expect {
        core.import("users", data)
      }.not_to raise_error
    end

    it "returns imported data count" do
      profile = {
        adapter: "sqlite3",
        database: 'tmp/arison_test.db',
        timeout: 500
      }

      core1 = Arison::Core.new(profile)
      data = [
        { email: "test1@example.com" },
        { email: "test2@example.com" },
        { email: "test3@example.com" }
      ]

      core1.import("emails", data)

      # Create new core instance for query
      core2 = Arison::Core.new(profile)
      results = core2.query("SELECT COUNT(*) as count FROM emails")
      expect(results.first['count']).to eq(3)
    end

    after(:all) do
      FileUtils.rm('tmp/arison_test.db', force: true)
    end
  end
end
