require 'spec_helper'

describe SessionManager do
  it "can create random keys" do
    (1..10000).map{ SessionManager.random_key }.uniq.size.should eq 10000
  end

  it "can store and retrieve an identity_id" do
    key = SessionManager.new_session(1313)
    SessionManager.identity_id_for_session(key).should eq 1313
  end

  it "returns nil for non existent keys" do
    SessionManager.identity_id_for_session("nonexistantsession").should be_nil
  end

  it "always returns nil for the nil key" do
    SessionManager.redis.set(nil, "1234")
    SessionManager.identity_id_for_session(nil).should be_nil
  end
end