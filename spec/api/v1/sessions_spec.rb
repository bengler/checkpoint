require 'spec_helper'

class TestCheckpointV1 < CheckpointV1; end

describe "API v1/auth" do
  include Rack::Test::Methods

  def app
    TestCheckpointV1
  end

  let :realm do
    Realm.create!(:label => "area51")
  end

  let :someone do 
    Identity.create!(:realm => realm)
  end

  let :somegod do
    Identity.create!(:god => true, :realm => realm)
  end

  let :false_god do
    Identity.create!(:god => true, :realm => Realm.create!(:label => 'hell'))
  end

  let :someone_session do
    SessionManager.new_session(someone.id)
  end

  let :somegod_session do
    SessionManager.new_session(somegod.id)
  end

  let :false_god_session do 
    SessionManager.new_session(false_god.id)
  end

  it "lets me inspect someone elses session, but only when I'm god" do
    get "/sessions/#{someone_session}", :session => somegod_session
    last_response.status.should eq 200
    JSON.parse(last_response.body)['identity']['id'].should eq someone.id
    get "/sessions/#{somegod_session}", :session => someone_session
    last_response.status.should eq 403
  end

  it "lets me creates a session for another user" do
    post "/sessions", :identity_id => someone.id, :session => somegod_session
    session = JSON.parse(last_response.body)['session']
    SessionManager.identity_id_for_session(session).should eq someone.id
    get "/identities/me", :session => session
    JSON.parse(last_response.body)['identity']['id'].should eq someone.id
  end

  it "won't let me create a session for others unless I'm a god and of the right realm" do
    post "/sessions", :identity_id => somegod.id, :session => someone_session
    last_response.status.should eq 403
    post "/sessions", :identity_id => somegod.id, :session => false_god_session
    last_response.status.should eq 403
  end

  it "lets me create another session for myself even if I'm no god" do
    post "/sessions", :session => someone_session
    last_response.status.should eq 200
    SessionManager.identity_id_for_session(JSON.parse(last_response.body)['session']).should eq someone.id
  end

  it "lets me kill other sessions at will" do
    delete "/sessions/#{someone_session}", :session => somegod_session
    get "/identities/me", :session => someone_session
    last_response.body.should eq '{}'
  end

  it "lets me persist sessions" do
    post "/sessions", :identity_id => someone.id, :session => somegod_session
    key = JSON.parse(last_response.body)['session']
    SessionManager.redis.ttl("session:#{key}").should > 0
    post "/sessions/#{key}/persist", :session => somegod_session
    SessionManager.redis.ttl("session:#{key}").should eq -1
  end

end
