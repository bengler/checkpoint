require 'spec_helper'

class TestCheckpointV1 < CheckpointV1; end

describe "Identities" do
  include Rack::Test::Methods

  def app
    TestCheckpointV1
  end

  let :realm do
    realm = Realm.create!(:label => "area51")
    Domain.create!(:realm => realm, :name => 'example.org')
    realm
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
    Identity.create!(:god => true, :realm => realm)
  end

  let :me_session do
    Session.create!(:identity => me).key
  end

  let :god_session do
    Session.create!(:identity => god).key
  end

  let(:json_output) { JSON.parse(last_response.body) }

  describe "GET /identities/me" do

    it "is possible to set current session with a http parameter" do 
      get "/identities/me", :session => me_session
      identity = JSON.parse(last_response.body)['identity']
      identity['id'].should eq me.id
    end

    it "describes me as a json hash" do
      get "/identities/me", :session => me_session

      identity = json_output['identity']
      identity['id'].should eq me.id
      identity['realm'].should eq me.realm.label

      json_output['accounts'].should eq ['twitter']

      profile = json_output['profile']
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

    it "hands me my balls if I ask for current user when there is no current user" do
      get "/identities/me"
      last_response.body.should eq "{}"
    end
  end

  describe "GET /identities/:identity_or_identities" do

    it "describes an identity as a json hash" do
      get "/identities/#{god.id}", :session => me_session
      JSON.parse(last_response.body)['identity']['id'].should eq god.id
    end

    it "returns multiple identities" do
      get "/identities/#{god.id},#{me.id}", :session => me_session
      result = JSON.parse(last_response.body)['identities']
      result.first['identity']['id'].should eq god.id
      result.first['accounts'].should eq([])
      result.first['profile'].should be_nil

      result.last['identity']['id'].should eq me.id
      result.last['accounts'].should eq(['twitter'])
      result.last['profile']['provider'].should eq('twitter')
    end

    it "returns empty identities if requested ids do not exist" do
      get "/identities/1024,1025,1026", :session => me_session
      empty_hash = {}
      result = JSON.parse(last_response.body)
      result['identities'].length.should eq 3
      result['identities'][0]['identity'].should eq empty_hash
      result['identities'][1]['identity'].should eq empty_hash
      result['identities'][2]['identity'].should eq empty_hash
    end

    it "can mix existing and non-existant identities" do
      get "/identities/1024,#{me.id},1026,#{god.id}", :session => me_session
      empty_hash = {}
      result = JSON.parse(last_response.body)
      result['identities'].length.should eq 4
      result['identities'][0]['identity'].should eq empty_hash
      result['identities'][1]['identity']['id'].should eq me.id
      result['identities'][2]['identity'].should eq empty_hash
      result['identities'].last['identity']['id'].should eq god.id
    end

    it "hands me a list of a single identity if I ask for it using a comma" do
      get "/identities/#{god.id},", :session => me_session
      result = JSON.parse(last_response.body)
      JSON.parse(last_response.body)['identities'].first['identity']['id'].should eq god.id
    end

  end

  describe "POST /identities" do
    it "creates an identity with an account" do
      parameters = {:session => god_session, :account => {:provider => 'twitter', :nickname => 'nick', :uid => '1'}}
      post '/identities', parameters
      last_response.status.should eq(200)

      result = JSON.parse(last_response.body)
      json_output['identity']['id'].should_not be_nil
      json_output['profile']["nickname"].should eq('nick')
    end

    it "can create god users" do
      parameters = {:session => god_session, :identity => {:god => true}, :account => {:provider => 'twitter', :nickname => 'nick', :uid => '1'}}
      post '/identities', parameters
      last_response.status.should eq(200)
      identity = json_output['identity']
      identity['id'].should_not be_nil
      identity['god'].should be_true
      json_output['profile']["nickname"].should eq('nick')
    end

    it "ignores any realm that is passed in" do
      god # trigger
      parameters = {:session => god_session, :identity => {:realm => 'rock_and_roll'}, :account => {:provider => 'twitter', :nickname => 'nick', :uid => '1'}}
      post '/identities', parameters
      last_response.status.should eq(200)

      identity = json_output['identity']
      identity['id'].should_not be_nil
      identity['realm'].should eq('area51')

      profile = json_output['profile']
      profile["nickname"].should eq('nick')
    end

    it "fails to create identities if not god" do
      parameters = {:session => me_session, :account => {:provider => 'twitter', :nickname => 'nick', :uid => '1'}}
      post '/identities', parameters
      last_response.status.should eq(403)
    end
  end

end
