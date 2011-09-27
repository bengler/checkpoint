require 'client_helper'

describe TwitterClient do
  it "uses the twitter log" do
    TwitterClient::CheckpointLogger.should_receive(:use).with(:twitter)
    TwitterClient.new(stub.as_null_object, stub)
  end
end
