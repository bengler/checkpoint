require 'spec_helper'

describe Authentication do
  it "knows the range of services" do
    Authentication::PROVIDERS.sort.should eq [:origo, :facebook, :twitter, :google].sort
  end
end