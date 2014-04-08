require 'spec_helper'

class TestCheckpointV1 < CheckpointV1; end

describe "Sessions" do
  include Rack::Test::Methods

  def app
    TestCheckpointV1
  end

  let :realm do
    Realm.create!(:label => "area51")
  end

  let :root_realm do
    realm = Realm.create!(:label => 'root')
    Domain.create!(:realm => realm, :name => 'immortal.dev')
    realm
  end

  let :root do
    Identity.create!(:god => true, :realm => root_realm)
  end

  let :root_session do
    Session.create!(:identity => root).key
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
    Session.create!(:identity => someone).key
  end

  let :somegod_session do
    Session.create!(:identity => somegod).key
  end

  let :false_god_session do 
    Session.create!(:identity => false_god)
  end

  it "lets me inspect someone elses session, but only when I'm god" do
    get "/sessions/#{someone_session}", :session => somegod_session
    last_response.status.should eq 200
    JSON.parse(last_response.body)['session']['identity_id'].should eq someone.id
    get "/sessions/#{somegod_session}", :session => someone_session
    last_response.status.should eq 403
  end

  it "lets me inspect my own session" do
    get "/session/", :session => someone_session
    last_response.status.should eq 200
    JSON.parse(last_response.body)['session']['key'].should eq someone_session
  end

  it "lets me create a session for another user" do
    post "/sessions", :identity_id => someone.id, :session => somegod_session
    last_response.status.should eq 200
    session = JSON.parse(last_response.body)['session']['id']
    Session.identity_id_for_session(session).should eq someone.id
    get "/identities/me", :session => session
    JSON.parse(last_response.body)['identity']['id'].should eq someone.id
  end

  it "won't let me create a session for others unless I'm a god and of the right realm" do
    post "/sessions", :identity_id => somegod.id, :session => someone_session
    last_response.status.should eq 403
    post "/sessions", :identity_id => somegod.id, :session => false_god_session
    last_response.status.should eq 403
  end

  it "will let a root identity create sessions for other realms" do
    post "/sessions", :identity_id => root.id, :session => root_session
    last_response.status.should eq 200
  end

  it "lets me create another session for myself even if I'm no god" do
    post "/sessions", :session => someone_session
    last_response.status.should eq 200
    Session.identity_id_for_session(JSON.parse(last_response.body)['session']['id']).should eq someone.id
  end

  it "updates my session" do
    post "/sessions", :session => someone_session
    last_response.status.should eq 200
    last_seen_on = Session.last.identity.last_seen_on
    Timecop.travel(1.day)
    post "/sessions", :session => someone_session
    last_response.status.should eq 200
    Session.count.should eq 1
    Session.last.identity.last_seen_on.should > last_seen_on
  end

  it "lets me kill other sessions at will when god on same realm or root" do
    delete "/sessions/#{someone_session}", :session => somegod_session
    get "/identities/me", :session => someone_session
    last_response.body.should eq '{}'
    delete "/sessions/#{someone_session}", :session => root_session
    get "/identities/me", :session => someone_session
    last_response.body.should eq '{}'
  end

  it "denies access trying to delete a session on another realm as god " do
    delete "/sessions/#{someone_session}", :identity_id => somegod.id, :session => false_god_session
    last_response.status.should eq 403
  end
end
