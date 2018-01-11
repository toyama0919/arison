# -*- coding: utf-8 -*-
require "thor"
require 'yaml'
require 'json'
require 'pp'

module Arison
  class CLI < Thor

    map '--version' => :version
    map '-s' => :query_inline
    map '-f' => :query_file
    map '-b' => :import

    class_option :profile, aliases: '-p', type: :string, default: 'default', desc: 'profile by .database.yml'
    class_option :pretty, aliases: '-P', type: :boolean, default: false, desc: 'pretty print'
    class_option :config, aliases: '--config', type: :string, default: "#{ENV['HOME']}/.database.yml", desc: 'config file'
    def initialize(args = [], options = {}, config = {})
      super(args, options, config)
      @global_options = config[:shell].base.options

      if @global_options[:config] && File.exist?(@global_options[:config])
        @config = YAML.load_file(@global_options[:config])
        profile = @config[@global_options[:profile]]
        @core = Core.new(profile)
      end
    end

    desc 'query_inline', 'Sample task'
    option :query, aliases: '-q', type: :string, required: true, desc: 'query'
    def query_inline
      puts_json @core.query(options[:query])
    end

    desc 'query_file', 'query_file'
    def query_file(file)
      puts_json @core.query(File.read(file))
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
    option :data, type: :hash, desc: 'buffer'
    option :source, aliases: '-s', type: :string, desc: 'source json file'
    option :table, aliases: '-t', type: :string, desc: 'table'
    def import
      data = (options[:data] ? [options[:data]] : nil) || @core.parse_json(STDIN.read)
      @core.create_table(options[:table], data)
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
