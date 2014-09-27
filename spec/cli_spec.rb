require 'spec_helper'
require 'pq'

describe Pq::CLI do
  before do
  end

  it "should stdout sample" do
    output = capture_stdout do
      Pq::CLI.start(['sample'])
    end
    output.should == "This is your new task\n"
  end

  after do
  end
end
