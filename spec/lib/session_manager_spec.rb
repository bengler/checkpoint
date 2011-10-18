require 'spec_helper'
require 'mock_redis'

describe SessionManager do
  it "can create random keys" do
    (1..10000).map{ SessionManager.random_key }.uniq.size.should eq 10000
  end

  it "can store and retrieve an identity_id" do
    mr = MockRedis.new
    SessionManager.connect(mr)
    key = SessionManager.new_session(1313)
    SessionManager.identity_id_for_session(key).should eq 1313
  end

  it "returns nil for non existent keys" do
    mr = MockRedis.new
    SessionManager.connect(mr)
    SessionManager.identity_id_for_session("nonexistantsession").should be_nil
  end
end