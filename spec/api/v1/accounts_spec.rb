require 'spec_helper'

class TestCheckpointV1 < CheckpointV1; end

describe "Accounts" do
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
    Identity.create!(:god => true, :realm => realm)
  end

  let :me_session do
    Session.create!(:identity => me).key
  end

  let :god_session do
    Session.create!(:identity => god).key
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

end
