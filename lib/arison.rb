require 'arison/version'
require 'arison/constants'
require 'arison/util'
require 'arison/core'
require 'arison/migration'
require 'arison/connection'
require 'arison/cli'

module Arison
  def self.import(table, data, config: DEFAULT_CONFIG_FILE_PATH, profile: DEFAULT_CONFIG_PROFILE)
    con = Connection.new(config: config, profile: profile)
    con.import(table, data)
  end
end
