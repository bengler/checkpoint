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

  let :stranger do
    Identity.create!(:realm => other_realm)
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

  let :group do
    Group.create!(:realm => realm, :label => "label")
  end

  let :other_group do
    Group.create!(:realm => other_realm, :label => "label")
  end

  let(:json_output) { JSON.parse(last_response.body) }

  describe "GET /groups" do
    it "returns the groups in the current realm" do
      Group.create!(:realm => realm, :label => "i_want_this")
      Group.create!(:realm => other_realm, :label => "not_that")
      get "/groups"
      json_output['groups'].first['group']['label'].should eq "i_want_this"
    end

    it "lists the subtrees for each group" do
      GroupSubtree.create!(:group => group, :location => "area51.a.b.c")
      get "/groups"
      json_output['groups'].first['group']['subtrees'].first.should eq "area51.a.b.c"
    end
  end

  describe "POST /groups/:label" do
    it "creates a group with a label" do
      realm
      post "/groups/label", :session => god_session
      group = Group.first
      group.label.should eq "label"
      group.realm_id.should eq realm.id
    end

    it "creates a group with no label" do
      realm
      post "/groups", :session => god_session
      group = Group.first
      group.label.should be_nil
    end

    it "will not create a group for non-gods" do
      post "/groups"
      last_response.status.should eq 403
      post "/groups", :session => me_session
      last_response.status.should eq 403
    end
  end

  describe "GET /groups/:identifier" do
    it "will retrieve a group by label or id" do
      group

      get "/groups/label"
      last_response.status.should eq 200
      JSON.parse(last_response.body)['group']['label'].should eq "label"

      get "/groups/#{group.id}"
      last_response.status.should eq 200
      JSON.parse(last_response.body)['group']['label'].should eq "label"
    end

    it "will not retrieve groups from other realms" do
      group = Group.create!(:realm => other_realm, :label => "the_consortium")
      get "/groups/the_consortium"
      last_response.status.should eq 404
    end

    it "will retrieve the correct group when two groups with the same label exists in different realms" do
      group
      Group.create!(:realm => other_realm, :label => "label")
      get "/groups/label"
      json_output['group']['id'].should eq group.id
    end
  end

  describe "DELETE /groups/:identifier" do
    it "will delete a group" do
      group
      delete "/groups/label", :session => god_session
      Group.count.should eq 0
    end

    it "will refuse to delete a group unless god" do
      group
      delete "/groups/label"
      last_response.status.should eq 403
      Group.count.should eq 1
    end
  end

  describe "PUT /groups/:group_identifier/memberships/:identity_id" do
    it "will create a membership" do
      put "/groups/#{group.id}/memberships/#{me.id}", :session => god_session
      Group.first.memberships.first.identity_id.should eq me.id
    end

    it "will refuse to create a membership unless god" do
      put "/groups/#{group.id}/memberships/#{me.id}"
      last_response.status.should eq 403
      Group.first.memberships.count.should eq 0
    end

    it "is idempotent" do
      put "/groups/#{group.id}/memberships/#{me.id}", :session => god_session
      put "/groups/#{group.id}/memberships/#{me.id}", :session => god_session
      GroupMembership.count.should eq 1
    end

    it "it refuses to add users from other realms" do
      put "/groups/#{group.id}/memberships/#{stranger.id}", :session => god_session
      last_response.status.should eq 403
    end
  end

  describe "DELETE /groups/:group_identifier/memberships/:identity_id" do
    it "will delete a membership" do
      GroupMembership.create!(:group => group, :identity => me)
      delete "/groups/#{group.id}/memberships/#{me.id}", :session => god_session
      GroupMembership.count.should eq 0
    end

    it "will refuse to delete a membership unless god" do
      GroupMembership.create!(:group => group, :identity => me)
      delete "/groups/#{group.id}/memberships/#{me.id}", :session => me_session
      GroupMembership.count.should eq 1
      last_response.status.should eq 403
    end

    it "is idempotent" do
      delete "/groups/#{group.id}/memberships/#{me.id}", :session => god_session
      last_response.status.should eq 204
    end
  end

  describe "PUT /groups/:identifier/subtrees/:location" do
    it "will add a subtree to the group" do
      put "/groups/#{group.id}/subtrees/area51.a.b.c", :session => god_session
      group.subtrees.first.location.should eq "area51.a.b.c"
    end

    it "will refuse to add a subtree unless god" do
      put "/groups/#{group.id}/subtrees/area51.a.b.c"
      last_response.status.should eq 403
      GroupSubtree.count.should eq 0
    end

    it "will refuse to add a subtree from a different realm" do
      put "/groups/#{group.id}/subtrees/route66.a.b.c", :session => god_session
      last_response.status.should eq 403
      GroupSubtree.count.should eq 0
    end

    it "is idempotent" do
      put "/groups/#{group.id}/subtrees/area51.a.b.c", :session => god_session
      put "/groups/#{group.id}/subtrees/area51.a.b.c", :session => god_session
      GroupSubtree.count.should eq 1
    end
  end

  describe "DELETE /groups/:group_identifier/subtrees/:location" do
    it "deletes a location from the group" do
      subtree = GroupSubtree.create!(:group => group, :location => "area51.a.b.c")
      delete "/groups/#{group.id}/subtrees/#{subtree.location}", :session => god_session
      GroupSubtree.count.should eq 0
    end

    it "refuses to delete unless god" do
      delete "/groups/#{group.id}/subtrees/area51.a.b.c"
      last_response.status.should eq 403
    end

    it "is idempotent" do
      delete "/groups/#{group.id}/subtrees/area51.a.b.c", :session => god_session
      last_response.status.should eq 204
    end
  end

  describe "GET /groups/:identifier/memberships" do
    it "will get the memberships for a group" do
      GroupMembership.create!(:group => group, :identity => me)
      get "/groups/#{group.id}/memberships"
      json_output['memberships'].size.should eq 1
      json_output['memberships'].first['membership']['identity_id'].should eq me.id
    end

    it "will only respond for groups in this realm" do
      get "/groups/#{other_group.id}/memberships"
      last_response.status.should eq 404
    end
  end

  describe "GET /identities/:id/memberships" do
    it "will get all memberships for a user and add a list of the groups involved for good measure" do
      GroupMembership.create!(:group => group, :identity => me)
      get "/identities/#{me.id}/memberships"
      json_output['memberships'].size.should eq 1
      json_output['memberships'].first['membership']['identity_id'].should eq me.id
      json_output['groups'].size.should eq 1
      json_output['groups'].first['group']['id'].should eq group.id
    end
  end
end
