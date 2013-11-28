require 'spec_helper'

class TestCheckpointV1 < CheckpointV1; end

describe "Domains" do
  include Rack::Test::Methods

  def app
    TestCheckpointV1
  end

  let :realm do
    realm = Realm.create!(:label => "area51")
    Domain.create!(:realm => realm, :name => 'example.org')
    realm
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
    Session.create!(:identity => false_god).key
  end

  it "provides details for a specific domain" do
    realm = Realm.create!(:label => 'area51')
    Domain.create!(:name => 'example.org', :realm => realm)
    get "/domains/example.org"
    result = JSON.parse(last_response.body)
    result['domain']['name'].should eq 'example.org'
    result['domain']['realm'].should eq 'area51'
  end

  # Deprecated. Remove when verified that it is not in use
  it "provides details for a specific domain" do
    realm = Realm.create!(:label => 'area51')
    Domain.create!(:name => 'example.org', :realm => realm)
    get "/realms/area51/domains/example.org"
    result = JSON.parse(last_response.body)
    result['domain']['name'].should eq 'example.org'
    result['domain']['realm'].should eq 'area51'
  end

  it "creates rules and tests if a host is allowed as an origin" do
    domain = Domain.create!(:name => 'mystuff.com', :realm => realm)
    get "/domains/mystuff.com/allows/example.org"
    result = JSON.parse(last_response.body)
    result['allowed'].should eq true
    get "/domains/mystuff.com/allows/pinshing.com"
    last_response.should be_ok, last_response.errors
    result = JSON.parse(last_response.body)
    result['allowed'].should eq false
    post "/realms/area51/domains/mystuff.com/origins", :origin => "pinshing.com", :session => somegod_session
    last_response.status.should == 201
    get "/domains/mystuff.com/allows/pinshing.com"
    result = JSON.parse(last_response.body)
    result['allowed'].should eq true
    delete "/realms/area51/domains/mystuff.com/origins/pinshing.com", :session => somegod_session
    last_response.status.should == 204
    get "/domains/mystuff.com/allows/pinshing.com"
    result = JSON.parse(last_response.body)
    result['allowed'].should eq false
  end

  it "lets gods attach a new domain to a realm, but not reattach it to another realm" do
    post "/realms/area51/domains", :name => "ditto.org", :session => somegod_session
    last_response.status.should eq 201
    Domain.find_by_name('ditto.org').realm.should eq realm
    post "/realms/area51/domains", :name => "wired.com", :session => someone_session
    last_response.status.should eq 403 # not okay because not god
    post "/realms/hell/domains", :name => 'ditto.org', :session => false_god
    last_response.status.should eq 403 # not okay because ditto.org committed to area51
  end

  describe "DELETE /realms/:realm/domains/:domain" do
    it "lets god delete a domain" do
      delete "/realms/area51/domains/example.org", :session => somegod_session
      last_response.status.should eq 204

      Domain.find_by_name('example.org').should be_nil
    end

    it "prevents regular identities from deleting domains" do
      delete "/realms/area51/domains/example.org", :session => someone_session
      last_response.status.should eq 403
    end

    it "prevents gods from deleting domains for other realms" do
      realm
      delete "/realms/hell/domains/example.org", :session => false_god_session
      last_response.status.should eq 403
      delete "/realms/area51/domains/example.org", :session => false_god_session
      last_response.status.should eq 403
    end
  end
end
