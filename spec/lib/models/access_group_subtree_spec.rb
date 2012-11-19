require 'spec_helper'

describe AccessGroup do
  let :realm do
    Realm.create!(:label => "area51")
  end

  let :access_group do
    AccessGroup.create!(:realm => realm, :label => "charta77")
  end

  it 'registers a path' do
    AccessGroupSubtree.create!(:access_group => access_group, :location => "area51.a.b.c")
    access_group.subtrees.size.should eq 1
  end

  it 'refuses invalid paths' do
    -> {
      AccessGroupSubtree.create!(:access_group => access_group, :location => "{$%&/()}")
    }.should raise_error(ActiveRecord::RecordInvalid)
  end

end