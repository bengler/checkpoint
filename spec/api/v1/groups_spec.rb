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

  let :other_realm do
    realm = Realm.create!(:label => "route66")
    Domain.create!(:realm => realm, :name => 'example.com')
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

  describe "GET /groups" do
    it "returns the groups in the current realm" do
      Group.create!(:realm => realm, :label => "i_want_this")
      Group.create!(:realm => other_realm, :label => "not_that")
      get "/groups"
      json_output['groups'].first['group']['label'].should eq "i_want_this"
    end
  end

end
