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

  let :root_realm do
    realm = Realm.create!(:label => 'root')
    Domain.create!(:realm => realm, :name => 'immortal.dev')
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

  let :stranger do
    Identity.create!(:realm => other_realm)
  end

  let :god do
    Identity.create!(:god => true, :realm => realm)
  end

  let :root do
    Identity.create!(:god => true, :realm => root_realm)
  end

  let :me_session do
    Session.create!(:identity => me).key
  end

  let :god_session do
    Session.create!(:identity => god).key
  end

  let :root_session do
    Session.create!(:identity => root).key
  end

  let :access_group do
    AccessGroup.create!(:realm => realm, :label => "label")
  end

  let :other_group do
    AccessGroup.create!(:realm => other_realm, :label => "label")
  end

  let(:json_output) { JSON.parse(last_response.body) }

  describe "GET /access_groups" do
    it "returns the groups in the current realm" do
      AccessGroup.create!(:realm => realm, :label => "i_want_this")
      AccessGroup.create!(:realm => other_realm, :label => "not_that")
      get "/access_groups"
      json_output['access_groups'].first['access_group']['label'].should eq "i_want_this"
    end

    it "lists the subtrees for each group" do
      AccessGroupSubtree.create!(:access_group => access_group, :location => "area51.a.b.c")
      get "/access_groups"
      json_output['access_groups'].first['access_group']['subtrees'].first.should eq "area51.a.b.c"
    end
  end

  describe "POST /access_groups/:label" do
    it "creates a group with a label" do
      realm
      post "/access_groups/label", :session => god_session
      group = AccessGroup.first
      group.label.should eq "label"
      group.realm_id.should eq realm.id
    end

    it "creates a group with no label" do
      realm
      post "/access_groups", :session => god_session
      group = AccessGroup.first
      group.label.should be_nil
    end

    it "will not create a group for non-gods" do
      post "/access_groups"
      last_response.status.should eq 403
      post "/access_groups", :session => me_session
      last_response.status.should eq 403
    end
  end

  describe "PUT /access_groups/:label" do
    it "creates a group with a label" do
      realm
      put "/access_groups/label", :session => god_session
      group = AccessGroup.first
      group.label.should eq "label"
      group.realm_id.should eq realm.id
    end

    it "updates a group in place" do
      realm
      put "/access_groups/label", :session => god_session
      last_response.status.should eq 201
      put "/access_groups/label", :session => god_session
      last_response.status.should eq 200
      group = AccessGroup.first
      group.label.should eq "label"
      group.realm_id.should eq realm.id
    end

    it "will fail with invalid labels" do
      put "/access_groups/1", :session => god_session
      last_response.status.should eq 400
    end

    it "will not create a group for non-gods" do
      post "/access_groups"
      last_response.status.should eq 403
      post "/access_groups", :session => me_session
      last_response.status.should eq 403
    end
  end

  describe "GET /access_groups/:identifier" do
    it "will retrieve a group by label or id" do
      access_group

      get "/access_groups/label"
      last_response.status.should eq 200
      JSON.parse(last_response.body)['access_group']['label'].should eq "label"

      get "/access_groups/#{access_group.id}"
      last_response.status.should eq 200
      JSON.parse(last_response.body)['access_group']['label'].should eq "label"
    end

    it "will not retrieve groups from other realms" do
      group = AccessGroup.create!(:realm => other_realm, :label => "the_consortium")
      get "/access_groups/the_consortium"
      last_response.status.should eq 404
    end

    it "will retrieve the correct group when two groups with the same label exists in different realms" do
      access_group
      AccessGroup.create!(:realm => other_realm, :label => "label")
      get "/access_groups/label"
      json_output['access_group']['id'].should eq access_group.id
    end
  end

  describe "DELETE /access_groups/:identifier" do
    it "will delete a group" do
      access_group
      delete "/access_groups/label", :session => god_session
      AccessGroup.count.should eq 0
    end

    it "will refuse to delete a group unless god" do
      access_group
      delete "/access_groups/label"
      last_response.status.should eq 403
      AccessGroup.count.should eq 1
    end
  end

  describe "PUT /access_groups/:group_identifier/memberships/:identity_id" do
    it "will create a membership" do
      put "/access_groups/#{access_group.id}/memberships/#{me.id}", :session => god_session
      AccessGroup.first.memberships.first.identity_id.should eq me.id
    end

    it "will refuse to create a membership unless god" do
      put "/access_groups/#{access_group.id}/memberships/#{me.id}"
      last_response.status.should eq 403
      AccessGroup.first.memberships.count.should eq 0
    end

    it "is idempotent" do
      put "/access_groups/#{access_group.id}/memberships/#{me.id}", :session => god_session
      put "/access_groups/#{access_group.id}/memberships/#{me.id}", :session => god_session
      AccessGroupMembership.count.should eq 1
    end

    it "it refuses to add users from other realms" do
      put "/access_groups/#{access_group.id}/memberships/#{stranger.id}", :session => god_session
      last_response.status.should eq 409
    end
  end

  describe "DELETE /access_groups/:group_identifier/memberships/:identity_id" do
    it "will delete a membership" do
      AccessGroupMembership.create!(:access_group => access_group, :identity => me)
      delete "/access_groups/#{access_group.id}/memberships/#{me.id}", :session => god_session
      AccessGroupMembership.count.should eq 0
    end

    it "will refuse to delete a membership unless god" do
      AccessGroupMembership.create!(:access_group => access_group, :identity => me)
      delete "/access_groups/#{access_group.id}/memberships/#{me.id}", :session => me_session
      AccessGroupMembership.count.should eq 1
      last_response.status.should eq 403
    end

    it "is idempotent" do
      delete "/access_groups/#{access_group.id}/memberships/#{me.id}", :session => god_session
      last_response.status.should eq 204
    end

    it "let's a root identity delete though" do
      delete "/access_groups/#{access_group.id}/memberships/#{me.id}", :session => root_session
      last_response.status.should eq 204
    end


  end

  describe "PUT /access_groups/:identifier/subtrees/:location" do
    it "will add a subtree to the group" do
      put "/access_groups/#{access_group.id}/subtrees/area51.a.b.c", :session => god_session
      access_group.subtrees.first.location.should eq "area51.a.b.c"
    end

    it "will refuse to add a subtree unless god" do
      put "/access_groups/#{access_group.id}/subtrees/area51.a.b.c"
      last_response.status.should eq 403
      AccessGroupSubtree.count.should eq 0
    end

    it "will refuse to add a subtree from a different realm" do
      put "/access_groups/#{access_group.id}/subtrees/route66.a.b.c", :session => god_session
      last_response.status.should eq 403
      AccessGroupSubtree.count.should eq 0
    end

    it "is idempotent" do
      put "/access_groups/#{access_group.id}/subtrees/area51.a.b.c", :session => god_session
      put "/access_groups/#{access_group.id}/subtrees/area51.a.b.c", :session => god_session
      AccessGroupSubtree.count.should eq 1
    end
  end

  describe "DELETE /access_groups/:group_identifier/subtrees/:location" do
    it "deletes a location from the group" do
      subtree = AccessGroupSubtree.create!(:access_group => access_group, :location => "area51.a.b.c")
      delete "/access_groups/#{access_group.id}/subtrees/#{subtree.location}", :session => god_session
      AccessGroupSubtree.count.should eq 0
    end

    it "refuses to delete unless god" do
      delete "/access_groups/#{access_group.id}/subtrees/area51.a.b.c"
      last_response.status.should eq 403
    end

    it "is idempotent" do
      delete "/access_groups/#{access_group.id}/subtrees/area51.a.b.c", :session => god_session
      last_response.status.should eq 204
    end
  end

  describe "GET /access_groups/:identifier/memberships" do
    it "will get the memberships for a group" do
      AccessGroupMembership.create!(:access_group => access_group, :identity => me)
      get "/access_groups/#{access_group.id}/memberships"
      json_output['memberships'].size.should eq 1
      json_output['memberships'].first['membership']['identity_id'].should eq me.id
    end

    it "will only respond for groups in this realm" do
      get "/access_groups/#{other_group.id}/memberships"
      last_response.status.should eq 404
    end
  end

  describe "GET /identities/:id/memberships" do
    it "will get all memberships for a user and add a list of the groups involved for good measure" do
      AccessGroupMembership.create!(:access_group => access_group, :identity => me)
      get "/identities/#{me.id}/memberships"
      json_output['memberships'].size.should eq 1
      json_output['memberships'].first['membership']['identity_id'].should eq me.id
      json_output['access_groups'].size.should eq 1
      json_output['access_groups'].first['access_group']['id'].should eq access_group.id
    end

    it "will do just fine with no data" do
      get "/identities/#{me.id}/memberships"
      json_output['memberships'].size.should eq 0
      json_output['access_groups'].size.should eq 0
    end
  end

  describe "GET /identities/:id/access_to/:path" do
    it "works" do
      AccessGroupSubtree.create!(:access_group => access_group, :location => "#{realm.label}.a.b.c")
      AccessGroupSubtree.create!(:access_group => access_group, :location => "#{realm.label}.x.y.z")
      AccessGroupMembership.create!(:access_group => access_group, :identity => me)

      get "/identities/#{me.id}/access_to/#{realm.label}.a.b.c.d.e"
      AccessGroup.paths_for_identity(me.id).should eq(["#{realm.label}.a.b.c", "#{realm.label}.x.y.z"])

      json_output['access']['granted'].should == true
    end

    it "doesn't grant access to unknown persons" do
      get "/identities/1/access_to/abc.a.b.c"
      json_output['access']['granted'].should == false
    end

  end

end
