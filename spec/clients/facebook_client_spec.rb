require 'client_helper'

describe FacebookClient do
  it "uses the facebook log" do
    FacebookClient::CheckpointLogger.should_receive(:use).with(:facebook)
    FacebookClient.new(stub, stub)
  end
end
