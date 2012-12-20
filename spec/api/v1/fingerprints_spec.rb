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

  it "returns a list of identities by their fingerprints" do
    identity = Identity.create!(:fingerprints => 'abcd123', :realm => realm)
    get "fingerprints/abcd123/identities"
    response = JSON.parse(last_response.body)
    response['identities'].size.should eq 1
    response['identities'].first['identity']['id'].should eq identity.id
  end

end
