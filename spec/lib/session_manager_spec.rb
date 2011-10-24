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
    SessionManager.redis.set('session:', "1234")
    SessionManager.identity_id_for_session(nil).should be_nil
  end

  it "knows how to create a session that expires and how to persist one" do
    key = SessionManager.new_session(1)
    # The default is just a very long lived session
    SessionManager.redis.ttl("session:#{key}").should > 1000000
    key = SessionManager.new_session(2, :expire => 1.hour)    
    SessionManager.redis.ttl("session:#{key}").should <= 1.hour
    SessionManager.persist_session(key)
    SessionManager.redis.ttl("session:#{key}").should eq -1
  end

  it "can store central profile information in redis" do
    realm = Realm.create!(:label => "realm")
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
    SessionManager.update_identity_record(identity)

    result = JSON.parse(SessionManager.redis.get("identity:#{identity.id}"))['identity']
    result['id'].should eq identity.id
    result['realm'].should eq identity.realm.label
    result['accounts'].should eq ['twitter']
    profile = result['profile']
    profile['provider'].should eq 'twitter'
    profile['nickname'].should eq 'nickname'
    profile['name'].should eq 'name'
    profile['profile_url'].should eq 'profile_url'
    profile['image_url'].should eq 'image_url'
  end
end