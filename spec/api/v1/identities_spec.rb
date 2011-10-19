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
    Thread.current[:identity] = identity
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

  it "describes me as a json hash" do
    Thread.current[:identity] = me
    get "/identities/me"
    result = JSON.parse(last_response.body)
    result['id'].should eq me.id
    result['realm'].should eq me.realm.label
    result['accounts'].should eq ['twitter']
    profile = result['profile']
    profile['provider'].should eq 'twitter'
    profile['nickname'].should eq 'nickname'
    profile['name'].should eq 'name'
    profile['profile_url'].should eq 'profile_url'
    profile['image_url'].should eq 'image_url'
    # And the result is the same if I ask for me by id
    Thread.current[:identity] = me
    former_response_body = last_response.body
    get "/identities/#{me.id}"
    last_response.body.should eq former_response_body
  end

  it "describes someone else as a json hash" do
    Thread.current[:identity] = me
    get "/identities/#{god.id}"
    JSON.parse(last_response.body)['profile']['nickname'].should eq 'god'
  end

  it "hands me my keys" do
    Thread.current[:identity] = me
    get "/identities/me/credentials/twitter"
    result = JSON.parse(last_response.body)
    result['identity'].should eq me.id
    result['uid'].should eq '1'
    result['token'].should eq 'token'
    result['secret'].should eq 'secret'
    result['provider'].should eq 'twitter'
  end

  it "refuses to hand me the keys of god" do
    Thread.current[:identity] = me
    get "/identities/#{god.id}/credentials/twitter"
    last_response.status.should eq 403
  end

  it "hands me anyones key if I'm god" do
    Thread.current[:identity] = god
    get "/identities/#{me.id}/credentials/twitter"
    result = JSON.parse(last_response.body)
    result['uid'].should eq '1'
    result['token'].should eq 'token'
    result['secret'].should eq 'secret'
  end
end
