require 'arison/version'
require 'arison/constants'
require 'arison/core'
require 'arison/migration'
require 'arison/cli'

module Arison
  def self.import(table, data, config: DEFAULT_CONFIG_FILE_PATH, profile: DEFAULT_CONFIG_PROFILE)
    params = ['import']
    params.concat(['--table', table])
    params.concat(['--data', data])
    params.concat(['--config', config])
    params.concat(['--profile', profile])
    Arison::CLI.start(params)
  end
end
