require 'spec_helper'

describe AccessGroup do
  let :realm do
    Realm.create!(:label => "area51")
  end

  it "can exist without a label" do
    AccessGroup.create!(:realm => realm)
  end

  it "if label provided, it must be a valid label that starts with a non-digit character" do
    AccessGroup.create!(:realm => realm, :label => "abc123")
    -> {
      AccessGroup.create!(:realm => realm, :label => "123abc")
    }.should raise_error(ActiveRecord::RecordInvalid)
  end

  it "can find a group by label or identifier alike" do
    access_group = AccessGroup.create!(:realm => realm, :label => "abc123")
    AccessGroup.by_label_or_id(access_group.id).first.should_not be_nil
    AccessGroup.by_label_or_id(access_group.label).first.should_not be_nil
  end

  it "returns the paths that an individual has access to" do
    access_group = AccessGroup.create!(:realm => realm, :label => "abc123")
    AccessGroupSubtree.create!(:access_group => access_group, :location => "area51.a.b.c")
    AccessGroupSubtree.create!(:access_group => access_group, :location => "area51.x.y.z")
    friend = Identity.create!(:realm => realm)
    AccessGroupMembership.create!(:access_group => access_group, :identity => friend)

    AccessGroup.paths_for_identity(friend.id).should eq(['area51.a.b.c', 'area51.x.y.z'])
  end
end
