require 'spec_helper'
require 'arison'
require 'json'

describe Arison::CLI do
  describe 'version command' do
    it "displays version" do
      output = capture_stdout do
        Arison::CLI.start(['version'])
      end
      expect(output.strip).to eq(Arison::VERSION)
    end
  end

  # CLI integration tests with file-based config are complex
  # These tests would require setting up proper config files
  # For now, we test the basic functionality and leave detailed CLI testing
  # for manual or integration test suites

  describe 'basic functionality' do
    it "responds to help command" do
      expect {
        Arison::CLI.start(['help'])
      }.not_to raise_error
    end
  end
end
