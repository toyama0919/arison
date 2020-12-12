require 'rspec'
require 'arison/version'

include Arison

def capture_stdout
  out = StringIO.new
  $stdout = out
  yield
  return out.string
ensure
  $stdout = STDOUT
end

def capture_stderr
  out = StringIO.new
  $stderr = out
  yield
  return out.string
ensure
  $stderr = STDERR
end

def get_core
  profile = {
    adapter: "sqlite3",
    database: 'tmp/core.db',
    timeout: 500
  }
  Core.new(profile)
end
