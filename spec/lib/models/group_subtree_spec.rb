require 'spec_helper'

describe Group do
  let :realm do
    Realm.create!(:label => "area51")
  end

  let :group do
    Group.create!(:realm => realm, :label => "charta77")
  end

  it 'registers a path' do
    GroupSubtree.create!(:group => group, :location => "a.b.c")
    group.subtrees.size.should eq 1
  end

  it 'refuses invalid paths' do
    -> {
      GroupSubtree.create!(:group => group, :location => "{$%&/()}")
    }.should raise_error(ActiveRecord::RecordInvalid)
  end

end