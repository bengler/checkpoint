require 'spec_helper'

describe Group do
  let :realm do
    Realm.create!(:label => "area51")
  end

  it "can exist without a label" do
    Group.create!(:realm => realm)
  end

  it "if label provided, it must be a valid label that starts with a non-digit character" do
    Group.create!(:realm => realm, :label => "abc123")
    -> {
      Group.create!(:realm => realm, :label => "123abc")
    }.should raise_error(ActiveRecord::RecordInvalid)
  end

  it "can find a group by label or identifier alike" do
    group = Group.create!(:realm => realm, :label => "abc123")
    Group.find_by_label_or_id(group.id).should_not be_nil
    Group.find_by_label_or_id(group.label).should_not be_nil
  end
end