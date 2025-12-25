require 'spec_helper'
require 'arison'

describe Arison::Connection do
  describe '#initialize' do
    context 'with config file and profile name' do
      before(:all) do
        FileUtils.mkdir_p('tmp')
        config = {
          'test' => {
            'adapter' => 'sqlite3',
            'database' => 'tmp/connection_test.db'
          }
        }
        File.write('tmp/connection_config.yml', config.to_yaml)
      end

      it "loads profile from config file" do
        connection = Arison::Connection.new(
          config: 'tmp/connection_config.yml',
          profile: 'test'
        )
        expect(connection).to be_a(Arison::Connection)
        expect(connection.core).to be_a(Arison::Core)
      end

      after(:all) do
        FileUtils.rm('tmp/connection_config.yml', force: true)
        FileUtils.rm('tmp/connection_test.db', force: true)
      end
    end

    context 'with direct profile hash' do
      it "accepts profile as hash" do
        profile = {
          adapter: 'sqlite3',
          database: 'tmp/direct_profile.db'
        }

        connection = Arison::Connection.new(profile: profile)
        expect(connection).to be_a(Arison::Connection)
        expect(connection.core).to be_a(Arison::Core)

        FileUtils.rm('tmp/direct_profile.db', force: true)
      end
    end

    context 'with invalid profile' do
      it "raises error for non-existent profile" do
        expect {
          Arison::Connection.new(
            config: '/nonexistent/config.yml',
            profile: 'invalid'
          )
        }.to raise_error(ArgumentError, /Profile 'invalid' not found/)
      end
    end
  end

  describe '#import' do
    let(:profile) do
      {
        adapter: 'sqlite3',
        database: 'tmp/connection_import_test.db'
      }
    end

    before(:all) do
      FileUtils.mkdir_p('tmp')
    end

    after do
      FileUtils.rm('tmp/connection_import_test.db', force: true)
    end

    it "imports data through connection" do
      connection = Arison::Connection.new(profile: profile)
      data = [
        { name: 'Alice', age: 30 },
        { name: 'Bob', age: 25 }
      ]

      expect {
        connection.import('users', data)
      }.not_to raise_error
    end
  end
end
