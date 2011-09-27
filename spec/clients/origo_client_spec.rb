require 'client_helper'

describe OrigoClient do
  it "uses the origo log" do
    OrigoClient::CheckpointLogger.should_receive(:use).with(:origo)
    OrigoClient.new(stub, stub)
  end
end
