require 'spec_helper'

class TestCheckpointV1 < CheckpointV1; end

describe "Bannings" do
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
    realm = Realm.create!(:label => "area52")
    Domain.create!(:realm => realm, :name => 'example.com')
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

  let :crook do
    result = Identity.new(:realm => realm)
    result.send(:fingerprints=, ['fingerprint1'])
    result.save!
    result
  end

  describe 'GET /bannings/:path' do
    context 'when god' do
      it "will get a list of relevant bans complete with identities" do
        crook
        banning1 = Banning.declare!(:path => "area51.a.b.c", :fingerprint => 'fingerprint1')
        banning2 = Banning.declare!(:path => "area51.z.m.q", :fingerprint => 'fingerprint1')
        get '/bannings/area51.a.b.c.d.e', :session => somegod_session
        response = JSON.parse(last_response.body)
        response['bannings'].size.should eq 1
        banning = response['bannings'].first['banning']
        banning['path'].should eq 'area51.a.b.c'
        banning['identities'].size.should eq 1
        banning['identities'].first['identity']['id'].should eq crook.id
      end

      it 'can filter on identity' do
        crook2 = Identity.new(:realm => realm)
        crook2.send(:fingerprints=, ['fingerprint2'])
        crook2.save!

        Banning.declare!(path: "area51", fingerprint: crook2.fingerprints.first)
        Banning.declare!(path: "area51", fingerprint: crook.fingerprints.first)

        get '/bannings/area51',
          session: somegod_session,
          identity_id: crook.id
        response = JSON.parse(last_response.body)
        response['bannings'].size.should eq 1
        banning = response['bannings'].first['banning']
        banning['path'].should eq 'area51'
        banning['identities'].size.should eq 1
        banning['identities'].first['identity']['id'].should eq crook.id

        get '/bannings/area51',
          session: somegod_session,
          identity_id: crook2.id
        response = JSON.parse(last_response.body)
        response['bannings'].size.should eq 1
        banning = response['bannings'].first['banning']
        banning['path'].should eq 'area51'
        banning['identities'].size.should eq 1
        banning['identities'].first['identity']['id'].should eq crook2.id
      end

      it 'fails with 403 if identity belongs to other realm' do
        foreigner = Identity.new(:realm => other_realm)
        foreigner.send(:fingerprints=, ['fingerprint1'])
        foreigner.save!

        get '/bannings/area51',
          session: somegod_session,
          identity_id: foreigner.id
        last_response.status.should eq 403
      end

      it 'fails if identity does not exist' do
        get '/bannings/area51',
          session: somegod_session,
          identity_id: 0
        last_response.status.should eq 404
      end
    end

    context 'when not god' do
      it 'should fail with 403' do
        crook
        get '/bannings/area51.a.b.c.d.e', :session => someone_session
        last_response.status.should eq 403
      end
    end
  end

  it "will create a ban, deleting any shadowed bans" do
    Banning.declare!(:path => "area51.a.b.c", :fingerprint => 'fingerprint1')
    Banning.declare!(:path => "area51.a.b.d", :fingerprint => 'fingerprint1')
    put "/bannings/area51.a/identities/#{crook.id}", :session => somegod_session
    last_response.status.should eq 201
    Banning.count.should eq 1
    Banning.first.path.should eq 'area51.a'
    Banning.first.fingerprint.should eq 'fingerprint1'
  end

  it "will not create a ban if more general ban is allready in place" do
    crook
    Banning.declare!(:path => "area51.a", :fingerprint => 'fingerprint1')
    put "/bannings/area51.a.b.c/identities/#{crook.id}", :session => somegod_session
    last_response.status.should eq 201
    Banning.count.should eq 1
    Banning.first.path.should eq 'area51.a'
  end

  it "will remove any necessary effective bans to lift ban on specific path for specific identity" do
    crook.send(:fingerprints=, ['fingerprint1', 'fingerprint2'])
    crook.save!
    Banning.declare!(:path => "area51.a", :fingerprint => 'fingerprint1')
    Banning.declare!(:path => "area51.a.b", :fingerprint => 'fingerprint2')
    delete "/bannings/area51.a.b.c.d.e/identities/#{crook.id}", :session => somegod_session
    last_response.status.should eq 200
    Banning.count.should eq 0
  end

  it "short circuits callbacks precluding any actual callback-processing" do
    Banning.declare!(:path => "area51.a", :fingerprint => 'fingerprint1')
    get "/callbacks/allowed/create/post.blog:area51.a.b.c", :identity => crook.id
    response = JSON.parse(last_response.body)
    response['allowed'].should be_false
    response['reason'].should_not be_nil
  end
end
