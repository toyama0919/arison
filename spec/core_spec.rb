require 'spec_helper'
require 'arison'

describe Arison::Core do
  before do
    @core = Core.new
  end

  it "core not nil" do
    @core.should_not nil
  end

  after do
  end
end
