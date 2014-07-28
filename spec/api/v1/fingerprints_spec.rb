require 'spec_helper'

class TestCheckpointV1 < CheckpointV1; end

describe "Fingerprints" do
  include Rack::Test::Methods

  def app
    TestCheckpointV1
  end

  let :realm do
    realm = Realm.create!(:label => "area51")
    Domain.create!(:realm => realm, :name => 'example.org')
    realm
  end

  let :somegod do
    Identity.create!(:god => true, :realm => realm)
  end

  let :somegod_session do
    Session.create!(:identity => somegod).key
  end

  let :someone do
    Identity.create!(:realm => realm)
  end

  let :someone_session do
    Session.create!(:identity => someone).key
  end

  let :realm do
    realm = Realm.create!(:label => "area51")
    Domain.create!(:realm => realm, :name => 'example.org')
    realm
  end

  it "returns a list of identities by their fingerprints" do
    identity = Identity.new(:realm => realm)
    identity.send(:fingerprints=, 'abcd123')
    identity.save!
    get "fingerprints/abcd123/identities"
    response = JSON.parse(last_response.body)
    response['identities'].size.should eq 1
    response['identities'].first['identity']['id'].should eq identity.id
  end

  describe "Adding fingerprints to existing identities" do
    context "when user is not god" do
      it "is *not* allowed to add new fingerprints" do
        identity = Identity.new(:realm => realm)
        identity.save!
        post "identities/#{identity.id}/fingerprints", fingerprints: ['23foo', '42bar'], :session => someone_session
        last_response.status.should eq 403
      end
    end
    context "when user is god" do
      it "is allowed to add fingerprints to an existing identity" do
        identity = Identity.new(:realm => realm)
        identity.save!
        post "identities/#{identity.id}/fingerprints", fingerprints: ['23foo', '42bar'], :session => somegod_session
        response = JSON.parse(last_response.body)
        response['identity']['fingerprints'].should include '23foo'
        response['identity']['fingerprints'].should include '42bar'
      end
    end
  end
end
