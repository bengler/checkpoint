require 'spec_helper'

class TestCheckpointV1 < CheckpointV1; end

describe "Realms" do
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

  it "gives me the realm of a domain" do
    realm = Realm.create!(:label => 'hell')
    Domain.create!(:name => 'example.org', :realm => realm)
    get "/domains/example.org/realm"
    result = JSON.parse(last_response.body)
    result['realm']['label'].should eq 'hell'
    result['realm']['domains'].should eq ['example.org']
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
      json_output['sessions'].first['session']['key'].should_not be_nil
    end

    it "fails with a non-root session" do
      some_guy = Identity.create!(:realm => realm)
      access = Session.create!(:identity => some_guy)
      post "/realms", :realm => {:label => 'unicorns'}, :session => access.key
      last_response.status.should eq 403
    end
  end

end
