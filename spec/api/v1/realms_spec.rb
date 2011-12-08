require 'spec_helper'

class TestCheckpointV1 < CheckpointV1; end

describe "API v1/auth" do
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

  it "lists the realms" do
    Realm.create!(:label => 'hell')
    Realm.create!(:label => 'area51')
    get "/realms"
    result = JSON.parse(last_response.body)
    result['realms'].sort.should eq ['hell', 'area51'].sort
  end

  describe "GET /realms/:realm" do
    context "without identity" do
      it "provides details for any realm" do
        get "/realms/#{realm.label}"
        result = JSON.parse(last_response.body)
        result['realm']['label'].should eq 'area51'
        result['realm']['domains'].should eq ['example.org']
        result.should_not have_key('sessions')
      end
    end

    context "as root" do
      it "includes a god session that can be used" do
        root_realm = Realm.create!(:label => 'root')
        root = Identity.create!(:realm => root_realm, :god => true)
        root_session = Session.create!(:identity => root)

        expected = somegod_session

        get "/realms/#{realm.label}", :session => root_session.key

        result = JSON.parse(last_response.body)
        result['realm']['label'].should eq 'area51'
        result['realm']['domains'].should eq ['example.org']
        result['sessions'].first["session"]["key"].should eq(expected)
      end
    end
  end

  it "provides details for a specific domain" do
    realm = Realm.create!(:label => 'area51')
    Domain.create!(:name => 'example.org', :realm => realm)
    get "/realms/area51/domains/example.org"
    result = JSON.parse(last_response.body)
    result['domain']['name'].should eq 'example.org'
    result['domain']['realm'].should eq 'area51'
  end

  it "lets gods attach a new domain to a realm, but not reattach it to another realm" do
    post "/realms/area51/domains", :name => "ditto.org", :session => somegod_session
    last_response.status.should eq 200
    Domain.find_by_name('ditto.org').realm.should eq realm
    post "/realms/area51/domains", :name => "wired.com", :session => someone_session
    last_response.status.should eq 403 # not okay because not god
    post "/realms/hell/domains", :name => 'ditto.org', :session => false_god
    last_response.status.should eq 403 # not okay because ditto.org committed to area51
  end

  describe "DELETE /realms/:realm/domains/:domain" do
    it "lets god delete a domain" do
      delete "/realms/area51/domains/example.org", :session => someone_session
      last_response.status.should eq 403 # must be god
      delete "/realms/area51/domains/example.org", :session => somegod_session
      last_response.status.should eq 200 # must be god
      Domain.find_by_name('example.org').should be_nil
    end

    it "prevents gods from deleting domains for other realms" do
      realm
      delete "/realms/hell/domains/example.org", :session => false_god_session
      last_response.status.should eq 403
      delete "/realms/area51/domains/example.org", :session => false_god_session
      last_response.status.should eq 403
    end
  end

  it "can tell me which realm I'm on" do
    get "/realms/current"
    JSON.parse(last_response.body)['realm'].should eq nil
    realm = Realm.create!(:label => 'area51')
    Domain.create!(:name => 'example.org', :realm => realm)
    get "/realms/current"
    json_output = JSON.parse(last_response.body)
    json_output['realm']['label'].should eq 'area51'
    json_output.should_not have_key('identity')
    json_output.should_not have_key('session')
  end

  describe "POST /realms" do
    it "succeeds with a root session" do
      realm = Realm.create!(:label => 'root')
      root = Identity.create!(:realm => realm, :god => true)
      access = Session.create!(:identity => root)
      post "/realms", :realm => {:label => 'rainbows'}, :domain => {:name => 'magical.org'}, :session => access.key
      last_response.status.should eq 200
      json_output = JSON.parse(last_response.body)
      json_output['realm']['label'].should eq 'rainbows'
      json_output['realm']['domains'].should eq ['magical.org']
      json_output['identity']['god'].should be_true
      json_output['session']['key'].should_not be_nil
    end

    it "fails with a non-root session" do
      some_guy = Identity.create!(:realm => realm)
      access = Session.create!(:identity => some_guy)
      post "/realms", :realm => {:label => 'unicorns'}, :session => access.key
      last_response.status.should eq 403
    end
  end

end
