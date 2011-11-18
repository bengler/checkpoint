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

  let :me do 
    identity = Identity.create!(:realm => realm)
    account = Account.create!(:identity => identity,
      :realm => realm,
      :provider => 'twitter',
      :uid => '1',
      :token => 'token',
      :secret => 'secret',
      :nickname => 'nickname',
      :name => 'name',
      :profile_url => 'profile_url',
      :image_url => 'image_url')
    identity.primary_account = account
    identity.save!
    identity
  end

  let :god do
    identity = Identity.create!(:god => true, :realm => realm)
    account = Account.create!(:identity => identity,
      :realm => realm,
      :provider => 'twitter',
      :uid => '2',
      :token => 'token',
      :secret => 'secret',
      :nickname => 'god',
      :name => 'name',
      :profile_url => 'profile_url',
      :image_url => 'image_url')
    identity.primary_account = account
    identity.save!
    identity
  end

  let :me_session do
    SessionManager.new_session(me.id)
  end

  let :god_session do
    SessionManager.new_session(god.id)
  end

  it "is possible to set current session with a http parameter" do 
    get "/identities/me", :session => me_session
    identity = JSON.parse(last_response.body)['identity']
    identity['id'].should eq me.id
  end

  it "describes me as a json hash" do
    get "/identities/me", :session => me_session
    result = JSON.parse(last_response.body)
    identity = result['identity']
    identity['id'].should eq me.id
    identity['realm'].should eq me.realm.label
    identity['accounts'].should eq ['twitter']
    profile = identity['profile']
    profile['provider'].should eq 'twitter'
    profile['nickname'].should eq 'nickname'
    profile['name'].should eq 'name'
    profile['profile_url'].should eq 'profile_url'
    profile['image_url'].should eq 'image_url'
    # And the result is the same if I ask for me by id
    former_response_body = last_response.body
    get "/identities/#{me.id}", :session => me_session
    last_response.body.should eq former_response_body
  end

  it "describes someone else as a json hash" do
    get "/identities/#{god.id}", :session => me_session
    JSON.parse(last_response.body)['identity']['id'].should eq god.id
  end

  it "hands me my keys" do
    get "/identities/me/accounts/twitter", :session => me_session
    result = JSON.parse(last_response.body)['account']
    result['identity_id'].should eq me.id
    result['uid'].should eq '1'
    result['token'].should eq 'token'
    result['secret'].should eq 'secret'
    result['provider'].should eq 'twitter'
  end

  it "refuses to hand me the keys for someone else" do
    get "/identities/#{god.id}/accounts/twitter", :session => me_session
    last_response.status.should eq 403
  end

  it "hands me anyones key if I'm god" do
    get "/identities/#{me.id}/accounts/twitter", :session => god_session
    result = JSON.parse(last_response.body)['account']
    result['uid'].should eq '1'
    result['token'].should eq 'token'
    result['secret'].should eq 'secret'
  end

  it "hands me a list of a single identity if I ask for it using a comma" do
   get "/identities/#{god.id},", :session => me_session
    JSON.parse(last_response.body)['identities'].first['identity']['id'].should eq god.id
  end

  it "hands me multiple identities if I ask for it" do
   get "/identities/#{god.id},#{me.id}", :session => me_session
    JSON.parse(last_response.body)['identities'].first['identity']['id'].should eq god.id
    JSON.parse(last_response.body)['identities'].last['identity']['id'].should eq me.id
  end

  it "hands me my balls if I ask for current user when there is no current user" do
    get "/identities/me"
    last_response.body.should eq "{}"
  end

end
