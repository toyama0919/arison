# -*- coding: utf-8 -*-
require "thor"
require 'json'
require 'pp'

module Arison
  class CLI < Thor

    map '--version' => :version
    map '-s' => :query
    map '-b' => :import

    class_option :profile, aliases: '-p', type: :string, default: DEFAULT_CONFIG_PROFILE, desc: 'profile by .database.yml'
    class_option :pretty, aliases: '-P', type: :boolean, default: false, desc: 'pretty print'
    class_option :config, aliases: '--config', type: :string, default: DEFAULT_CONFIG_FILE_PATH, desc: 'config file'
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

    desc 'query_inline', 'Sample task'
    option :query, aliases: '-q', type: :string, desc: 'query'
    option :file, aliases: '-f', type: :string, desc: 'file'
    def query
      file_sql = if options[:file] && File.exist?(options[:file])
        File.read(options[:file])
      end
      query = options[:query] || file_sql || STDIN.read
      puts_json @core.query(query)
    end

    desc 'tables', 'tables'
    def tables
      puts_json @core.tables
    end

    desc 'columns', 'columns'
    option :table, aliases: '-t', type: :string, desc: 'table'
    def columns
      puts_json @core.columns_with_table_name(options[:table])
    end

    desc 'import', 'import json data.'
    option :table, aliases: '-t', type: :string, desc: 'table'
    option :data, type: :hash, desc: 'buffer'
    def import
      data = (options[:data] ? options[:data] : nil) || Util.parse_json(STDIN.read)
      data = [data] if data.class == Hash
      @core.import(options[:table], data)
    end

    desc 'info', 'info'
    def info
      puts_json @config
    end

    desc 'version', 'show version'
    def version
      puts VERSION
    end

    private
    def puts_json(object)
      puts JSON.pretty_generate(object)
    end
  end
end
