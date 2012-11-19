require 'spec_helper'

describe AccessGroup do
  let :realm do
    Realm.create!(:label => "area51")
  end

  let :wrong_realm do
    Realm.create!(:label => "route66")
  end

  let :access_group do
    AccessGroup.create!(:realm => realm, :label => "charta77")
  end

  let :friend do
    Identity.create!(:realm => realm)
  end

  let :stranger do
    Identity.create!(:realm => wrong_realm)
  end

  it 'connects a member' do
    AccessGroupMembership.create!(:access_group => access_group, :identity => friend)
    access_group.memberships.size.should eq 1
  end

  it 'refuses to enroll members from a different realm' do
    -> {
      AccessGroupMembership.create!(:access_group => access_group, :identity => stranger)
    }.should raise_error(ActiveRecord::RecordInvalid)
  end

end