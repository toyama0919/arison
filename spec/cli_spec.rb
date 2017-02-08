require 'spec_helper'
require 'arison'

describe Arison::CLI do
  before do
  end

  it "should stdout sample" do
    output = capture_stdout do
      Arison::CLI.start(['sample'])
    end
    output.should == "This is your new task\n"
  end

  after do
  end
end
